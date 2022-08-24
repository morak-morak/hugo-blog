---
categories: spring
date: "2022-08-21T00:00:00Z"
tags: ['spring', 'transctional', 'scheduled']
title: '# 스프링 @Scheduled 와 @Transactional에 얽힌 이야기'
author: '차리'
---
 

# 0. 서론
팀 프로젝트를 진행하면서, 특정 시간에 맞추어 Entity의 상태를 업데이트하고, 슬랙 메시지를 발송하는 기능을 개발하고 있었습니다. 제이슨이 추천해주신 여러가지 선택지 중에서, 러닝커브나 유지보수성을 감안하여 스프링의 스케줄링 기능을 활용하기로 결정했고, 약간의 학습 이후 본격적인 개발에 착수했습니다. 

코드는 대략 다음과 같이 구성되어 있었습니다.

```java
@Service
@Transactional
public class PollService {

	@Scheduled(cron = "0 0/1 * * * ?")
	void notifyClosedByScheduled() {
		List<Poll> pollsToBeClosed = pollRepository.findAllToBeClosed(LocalDateTime.now());
		for (Poll poll : pollsToBeClosed) {
			poll.close(poll.getHost());
			notificationService.notifyMenuStatus(
					poll.getTeam(), MessageFormatter.formatClosed(FormattableData.from(poll))
			);
		}
	}
}
```

대략 위와 같이 서비스가 구성되어 있었고, `poll` entity 내부에서는 `member(host)` 객체를 `lazy loading` 하고 있는 상황이었습니다. 이번 포스팅에서는 위와 같은 상황에서 겪었던 `Transactional`이 동작하지 않는 문제와, 이를 해결하면서 알게된 (기초적인) 사실들을 이야기해보고자 합니다.

# 1. 발단
> could not initialize proxy - no session

가장 첫 번째로 당면한 문제는 프록시 초기화 문제였습니다. 위와 같은 상황에서, poll 객체의 상태를 close하기 위해서 주어진 member가 host인지 확인합니다. host를 직접 꺼내다 다시 넣어주었으니, 로직상 문제는 없었죠. 하지만 같은 객체인지 비교하기 위해 `equals` 메소드가 호출되는 순간, 위와 같은 문제가 발생했습니다.

가장 첫 번째로 의심한 부분은 `Transaction` 여부였습니다. JPA의 객체는 기본적으로 `Transaction` 하위에 있는 영속성 컨텍스트 내부에서 활동하고, 영속성 컨텍스트가 끊어지면, 즉 `Transaction`이 끊어지면 위와 같은 문제가 발생하기 때문입니다.

테스트 코드에서는 잘 동작하던 코드였기에, 어느 부분이 문제인지 확인이 되지 않았습니다. 따라서 `application.yml` 에 다음과 같은 설정을 추가하고 스케줄링 동작시 로그를 확인해보았습니다.

```yml
logging:
  level:
    org:
      springframework:
        transaction.interceptor: TRACE
```

위 설정은 트랜잭션이 언제 동작하는지 확인할 수 있는 설정입니다.([참고](https://www.baeldung.com/spring-transaction-active#using-spring-transaction-logging))

```log
[2022-08-22 21:50:19:3733][scheduled-task-pool-1] TRACE o.s.t.i.TransactionInterceptor - No need to create transaction for [org.springframework.data.jpa.repository.support.SimpleJpaRepository.findAllToBeClosed]: This method is not transactional.
Hibernate: 
    {쿼리문}
```

제가 class level에 분명히 `@Transactional` 어노테이션을 붙였음에도 불구하고, 메소드를 호출할 때에는 `Transaction` 을 생성하는 로그가 찍히지 않았습니다. 대신, 위와 같이 조회 쿼리일때에는 "트랜잭션이 필요없다" 라는 로그만 뱉어주고 있었죠. 게다가 더욱 아이러니한 점은, `save` 메소드를 호출할 때에는 트랜잭션을 잠깐 얻고, 쿼리를 날린 후 곧바로 종료시켜버리고 있었습니다.

# 2. 의문 하나.
문제를 해결하기에 앞서, 가장 먼저 의문이 들었던 부분은 ?왜 `save`를 할 때는 `transaction`이 동작하고, `findAllTobeClosed` 와 같은 조회 쿼리는 동작하지 않았을까?" 였습니다.

그 원인은, JPA가 조회하는 로직일때는 `transaction`이 필요하지 않기 때문입니다. 다음은 [한 스택오버플로우 글](https://stackoverflow.com/questions/21672454/application-managed-jpa-when-is-transaction-needed)에서 인용한 JTA spec의 일부입니다.

> The persist, merge, remove, and refresh methods must be invoked within a transaction context when an entity manager with a transaction-scoped persistence context is used. If there is no transaction context, the javax.persistence.TransactionRequiredException is thrown.

> The find method (provided it is invoked without a lock or invoked with LockModeType.NONE) and the getReference method are not required to be invoked within a transaction context. If an entity manager with transaction-scoped persistence context is in use, the resulting entities will be detached; if an entity manager with an extended persistence context is used, they will be managed. See section 3.3 for entity manager use outside a transaction.

즉, 조회로직은 transaction context 내에서 일어날 필요가 없다는 뜻입니다. 그렇다면 `save`는 어떨까요? 이는 `SimpleJpaRepository`를 살펴보면 알 수 있습니다.

SimpleJpaRepository는 Repository 인터페이스의 최상위 구현체이자, CrudRepository의 default 구현체입니다. 우리가 Repository 혹은 JpaRepository를 상속한 인터페이스를 만들면, `JpaRepositoryFactoryBean`가 `SimpleJpaRepository` 를 상속하여 만든 프록시 객체로 우리가 만든 인터페이스의 구현체를 생성합니다. 

![](/assets/images/spring-scheduled-with-transactional/2022-08-24-13-20-01.png)

그리고 이 `SimpleJpaRepository` 에는 `save` 메소드가 기본으로 구현되어있으며, 여기에는 `@Transactional` 어노테이션이 붙어있습니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-24-13-40-57.png)

# 3. 의문 둘.
두 번째로 들었던 의문은 "왜 service method 레벨에서 transaction이 걸리지 않았을까 ?" 입니다. 처음에 구글링을 통해 얻었던 정보는 "스케줄러와 서비스를 분리해라" 였습니다. 말인즉슨, `@Scheduled` 가 먼저 처리되고 나서 `@Transactional` 이 처리되기 때문에, 등록된 `@Scheduled` 는 `@Transactional` 과 상관이 없다는 것입니다. 

또 다른 정보로는, `PlatformTransactionManager` 의 default 구현체가 `DataSourceTransactionManager` 인 경우, JPA 스펙 구현체인 `Hibernate`의 `AbstractTransactionImpl` 안에 있는 `begin` 메소드를 호출하지 않는다는 것이고, 따라서 커스텀하게 TransactionManager를 설정해주어야 한다는 정보였습니다.

하지만 결론부터 말씀드리자면 제 경우에는 둘 다 해당하지 않았습니다. `@Scheduled` 와 `@Transactional` 어노테이션이 처리되는 순서에 대해서 살펴보았을 때에도 문제가 없었고, 제가 사용하고 있던 트랜잭션 매니저는 `JpaTransactionManager` 였습니다.

> 제가 현재 사용하고 있는 스프링부트 버전은 2.6.6 이고, hibernate 버전은 5.6.7 입니다.

눈치채셨을지도 모르겠지만 해결법은 의외로 기초적이고 간단한 내용이었는데, 바로 **서비스 메소드의 접근제어자를 public으로 선언하는 것**이었습니다. 외부 패키지(e.g. controller) 에서 사용할 수 없도록 접근제어자를 package-private으로 두었는데, 이것이 화근이었습니다.

이는 [공식문서](https://docs.spring.io/spring-framework/docs/current/reference/html/data-access.html#transaction-declarative-annotations-method-visibility)에서도 잘 나와있는 내용이었습니다.

> When you use transactional proxies with Spring’s standard configuration, you should apply the @Transactional annotation only to methods with public visibility. If you do annotate protected, private, or package-visible methods with the @Transactional annotation, no error is raised, but the annotated method does not exhibit the configured transactional settings. 

그렇다면 또 다시 드는 의문은 왜 꼭 "public이어야 하는가?" 입니다. 이 또한 [Spring Core 공식문서 중 AOP](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#aop-pointcuts-designators) 내용을 뒤져보면 간략하게나마 알 수 있습니다.


> Due to the proxy-based nature of Spring’s AOP framework, calls within the target object are, by definition, not intercepted. For JDK proxies, only public interface method calls on the proxy can be intercepted. With CGLIB, public and protected method calls on the proxy are intercepted (and even package-visible methods, if necessary). However, common interactions through proxies should always be designed through public signatures.

즉, JDK 프록시는 `public` 메소드만 intercept 할 수 있고, CGLIB은 `package-private` 까지 가져올수 있지만, 일반적으로 `public` 시그니쳐를 통해 동작하도록 되어있다는 내용입니다.

참고로, 이와 같은 사실을 통해, 다음과 같은 설정으로 `@Transactional`이 `protected`나 `package-private` 에서도 동작하게 만들 수는 있습니다. 자세한 내용은 [이곳](https://docs.spring.io/spring-framework/docs/current/reference/html/data-access.html#transaction-declarative-annotations-method-visibility)을 참고하세요

```java
/**
 * Register a custom AnnotationTransactionAttributeSource with the
 * publicMethodsOnly flag set to false to enable support for
 * protected and package-private @Transactional methods in
 * class-based proxies.
 *
 * @see ProxyTransactionManagementConfiguration#transactionAttributeSource()
 */
// @EnableTransactionManagement 이 등록되어 있어야 합니다.
@Bean
TransactionAttributeSource transactionAttributeSource() {
    return new AnnotationTransactionAttributeSource(false);
}
```


# 4. 부록.
스케줄링이 어떻게 동작하는지 한번 코드로 살펴보았습니다.

스프링에는 의존관계를 주입하며 bean을 생성하는 `AutowireCapableBeanFactory`가 있습니다. 아래 위 코드는 해당 인터페이스의 추상 클래스인 `AbstractAutowireCapableBeanFactory` 중 일부입니다 (line 450)

![](/assets/images/spring-scheduled-with-transactional/2022-08-22-23-26-19.png)

위 코드에서 알 수 있다시피, bean을 등록하고 난 뒤, `post-processor`에 의해 후처리 작업을 진행합니다. 후처리 작업은 post-processor에 의해 처리된 결과가 `null`이 아니라면 계속해서 바꿔치기를 진행합니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-22-23-32-30.png)

여기서 `getBeanPostProcessor()`를 확인해보면, 15개의 `post-processor`가 등록되어있는 것을 확인할 수 있습니다. 이 중, 5번째에 해당하는 `AnnotationAwareAspectJAutoProxyCreator` 가 `@Transactional` 어노테이션을 처리하는 녀석입니다. 그리고, 14번째에 있는 `ScheduledAnnotationBeanPostProcessor` 가 바로 `@Scheduled` 어노테이션을 처리하는 녀석이구요.

![](/assets/images/spring-scheduled-with-transactional/2022-08-22-23-37-13.png)

그리고 Transactional을 위해 `AnnotationAwareAspectJAutoProxyCreator` 에 의해, 처리 되기 전(result)에는 일반 객체였지만, 처리된 녀석(current)이 프록시 객체임을 확인할 수 있습니다.

그렇다면 스케줄링은 어떻게 등록되고, 실행될까요 ?
`ScheduledAnnotationBeanPostProcessor` 로 이동해보겠습니다.

앞서 보았던 `postProcessAfterInitialization()` 메소드 내부를 살펴보면, 

![](/assets/images/spring-scheduled-with-transactional/2022-08-22-23-49-22.png)

아래와 같이 `@Scheduled` 어노테이션이 붙어있는 메소드들에 대해서, `processScheduled()` 메소드 를 호출하고 있음을 확인할 수 있습니다. 해당 메소드로 다시 넘어가보겠습니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-23-00-21-19.png)

위 코드는 `fixedDelay`, `cron` 등 `@Scheduled` 어노테이션에 달았던 여러 설정값을 처리하고, 이를 task로 만드는 작업을 진행합니다. (코드가 너무 길어, `cron` 부분만 떼왔습니다.) 그리고 나서, `registrar` 에 `CronTask`를 등록합니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-23-00-24-09.png)

당장은 빨간 박스로 친 부분만 실행된다는 점에 유의해서 살펴보시면 됩니다. 새로 등록된 Task이므로, `CronTask` 리스트에 등록하면서, 동시에 `unresolvedTask`에 등록합니다.

여기까지 진행한 다음, 빈 초기화가 모두 끝난 이후를 확인해보겠습니다. 애플리케이션이 실행되고나면, `SimpleApplicationEventMultiCaster` 의 `multicast` 를 호출해 `ApplicationListener` 에게 `invoke` 할 것을 명령합니다. 

![](/assets/images/spring-scheduled-with-transactional/2022-08-23-00-13-43.png)

이 `Listener` 중 하나가 방금 보았던 `ScheduledAnnotationBeanPostProcessor` 입니다. 그리고 `invoke()`는 `onApplicationEvent()`를, `onApplicationEvent()`는 `finishRegistration()`을 순차적으로 호출합니다. 이 때, 우리가 등록한 `SchedulingConfigurer` Configuration이 있다면 이를 등록합니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-25-00-33-22.png)

즉, 위의 `List<SchedulingConfigurer> configures` 에 아래 코드와 같이 우리가 정의한 configuration이 들어갑니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-25-00-44-35.png)


그리고 `finishRegistration()`은 최종적으로 `this.registrar.afterPropertiesSet();` 을, 그리고 이는 `registrar` 내부의 `scheduleTasks()`를 호출합니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-23-00-29-39.png)

그러면 앞서 익숙한 메소드명이 보입니다. 바로 `scheduleCronTask()` 입니다. 

![](/assets/images/spring-scheduled-with-transactional/2022-08-23-00-31-08.png)

`taskScheduler`가 null이 아니기때문에(앞서 커스텀 정의한 configuration에서 `ThreadPoolTaskScheduler`을 넣어줬으니까요.), future에 `ScheduledFuture` 를 넣어줍니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-25-01-01-21.png)

넣어준 `ScheduledFuture` 의 구현체는 `ReschedulingRunnable`로, 자기 자신이 실행해야할 시각을 설정합니다. 그리고 java에 의해 설정된 시각에 동작합니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-25-01-03-59.png)

자, 이제 마무리입니다. java에 의해 `run` 메소드가 호출되면, 해야 할 일을 수행하고, triggerContext에 의해 다음 실행 시각을 다시 계산한뒤 `schedule` 을 다시 호출합니다.

![](/assets/images/spring-scheduled-with-transactional/2022-08-25-01-01-21.png)

# 5. 마무리.
사실 처음 작성했던 코드가 의도한대로 동작하지 않았던 문제의 해결방법은 그리 어렵지 않았습니다. 단순히 `public` 접근제어자를 붙이기만 해주면 되니까요. 하지만 그 이면에서 왜 이런 문제가 발생했는지, `@Scheduled`가 어떻게 동작하는지 등의 궁금증을 해결할 수 있는 계기가 되었습니다.

트러블슈팅과 관련해서 레퍼런스도 많이 발견하지 못했는데, 혹여라도 난항을 겪는 분들께 도움이 되었길 바라겠습니다. 감사합니다.
