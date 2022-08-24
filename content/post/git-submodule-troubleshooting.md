---
categories: git
date: "2022-07-01T00:00:00Z"
tags: ['git', 'submodule', 'trouble-shooting']
title: '# 깃 서브모듈 트러블슈팅'
author: '백엔드-차리'
---
 
# 깃 서브모듈 트러블슈팅
: 우테코 레벨3를 시작하면서, 본격적인 팀 프로젝트 작업에 착수했습니다. 여러가지 의견이 오고가던 중, 개인이 공부한 내용을 정리하는 블로그를 하나 만들자는 이야기가 나왔습니다. 공동의 소유라는 느낌을 갖기 위해, github organization 에 github blog를 만들기로 했죠. M1 맥에서 ruby & ruby bundle에 대한 문제를 겪었던 저와 다른 팀원의 경험을 토대로, 흔히 사용하는 `jekyll` 대신, `hugo` 를 사용하기로 결정하였습니다. 또한, 지금 현재 제가 사용하고 있는 깃허브 블로그도 hugo 로 제작되었기 때문에, 제가 블로그의 생성을 맡았습니다. 

`hugo` 블로그는 보통 submodule을 기반으로 제작됩니다. `jekyll`의 경우 깃허브 자체에서 지원해주는 정적 사이트 생성기이기 때문에, 따로 빌드를 하지 않아도 됐던 것으로 기억합니다. 하지만 hugo는 그렇지 않습니다. 따라서 hugo 자체에서 지원해주는 기능으로 정적 사이트를 빌드한 뒤, 빌드 결과물을 깃허브에 업로드해야 합니다. 대개 다음과 같은 구조를 가집니다.

![](/assets/images/git-submodule-troubleshooting/2022-07-02-23-22-23.png)

메인 모듈에서 테마를 include 해온 뒤, 블로그 글을 작성하고, static site를 생성한 뒤, 그 결과물을 github에 업로드하는 방식입니다. 제가 블로그를 생성한 상황에서는 위와 같이 메인, 그리고 public 이라는 빌드 결과물이 깃허브에 업로드된 상태였습니다. 앞으로 메인 모듈을 '메인', public을 '서브' 로 축약해서 이야기하도록 하겠습니다.

이전 생성 경험을 토대로 제작하는데에 큰 무리가 없었는데, 팀원들이 테스트를 시작하자 문제가 발생했습니다. 제가 혼자 사용할 때는 문제가 없었는데, 팀원들이 사용하려고 깃허브에서 clone 해오는 순간 문제가 발생한 것이죠. 프로젝트에서도 서브모듈을 활용하기로 결정되어 있었기 때문에, 해당 문제는 꼭 해결해야 한다는 생각이 들어, 이를 해결한 기록을 남겨보고자 합니다.

발생한 문제는 총 두 가지였습니다. 하나씩 살펴보도록 하겠습니다.

## 메인 git clone 시 submodule을 가져오지 않는다.
: 메인을 clone 해오는 경우, 자연스럽게 submodule도 가져올 것이라고 예상할 수 있습니다. 하지만 예상과 달리 submodule은 가져오지 않고, 가져오려고 해도 제대로 동작하지 않았습니다. 서브모듈에 대한 개념이 부족했던 지라, '서브모듈에 대한 정보를 가져오지 않는걸까?' 라는 생각이 들어 서브모듈을 직접 추가해보았습니다.

`git submodule add -b ${branch} https://github.com/${organization}/${sub_repository} public`

위 명령어는 서브모듈이 존재하는 repository 를 현재 깃 프로젝트에 추가하되, `${branch}` 라는 이름의 브랜치를 가져오고, 그 이름을 `public` 으로 설정하겠다는 의미입니다. 따라서 public 이라는 디렉토리에 서브모듈로 등록됩니다. (public은 hugo에서 빌드 결과물을 생성해놓는 디렉토리입니다.) 그런데 위와 같은 명령어를 실행할 경우, 다음과 같은 메세지가 등장합니다.

```
'public' already exists in the index
```

뭔가 이상합니다. `public`에 대한 정보를 이미 가져온 것일까요 ? 이는 반만 맞습니다. 정확히는, submodule이 존재한다는 것, 그리고 그 녀석의 이름이 `public` 이라는 것 까지는 알고 있습니다. 코드를 한 곳에서 관리하는 것이 효율적이기 때문에, submodule의 소스코드는 별도의 repository에서 관리하는 상태입니다. 따라서 서브가 이미 존재하니, 깃은 '인덱스에 이미 존재한다' 라고 대답합니다. `git submodule status` 를 입력하면 다음과 같습니다.

```bash
git submodule status 
                                                              
-d2d76400942ad9fe3616f60775053a32750d3bbb public
-9af128a8a638d139771afc30a8f331a73ce810b1 themes/PaperMod
```

submodule에 대한, 즉 '서브' 프로젝트에 대한 상세 정보는 가져오지 못한 상태입니다. 이는 프로젝트의 `.git` 디렉토리를 확인해보면 알 수 있습니다. 프로젝트를 생성한 제 로컬에서는 `.git/modules` 디렉토리를 가보면 `public`, 그리고 테마와 관련된 `/themes/${theme}` 이 있는 것을 확인할 수 있습니다. 하지만 clone 해온 팀원의 프로젝트에서는 위 `modules` 디렉토리 자체가 없거나, 있더라도 그 내부가 비어있음을 확인할 수 있습니다.

아무튼 이 정보를 알려주기 위해선 `.gitmodules` 라는 특수한 파일이 필요합니다. 해당 파일을 생성한 뒤, 다음과 같은 내용을 추가해주었습니다.

```bash
[submodule "public"]
	path = public
	url = https://github.com/${organization}/${sub_repository}
	branch = ${branch}
[submodule "themes/${theme}"]
	path = themes/${theme}
	url = https://github.com/${organization}/${theme_repository}
	branch = ${branch}
```

그리고, 다음의 두 명령어를 통해 submodule의 상세정보를 등록하고, 가져옵니다.

```bash
git submodule init
git submodule update
```

이렇게 하면, 이제 `public` 디렉토리에 서브모듈에 대한 소스코드까지 포함되어 있는 것을 확인할 수 있습니다. 만약 `.gitmodules` 라는 파일이 remote(깃허브)에도 작성되어 있다면, 다음부터는 clone 해올 때 `--recursive` 혹은 `--resurse-submodules` 라는 옵션을 줘서 `init` 과 `update` 를 한번에 진행할 수 있습니다.

```bash
git clone ${main_repo} --recursive
# 혹은
git clone ${main_repo} --recurse-submodules
```

## 메인 git clone 시 ref 에러가 발생한다.
: 정확한 에러 문구는 다음과 같습니다. 

`fatal: remote error: upload-pack: not our ref ${commit-id}`

대충 다음과 같이 생겼습니다.

![](/assets/images/git-submodule-troubleshooting/2022-07-03-00-04-18.png)

이 또한 submodule 의 특수성으로 인해 발생하는 문제입니다. 결론부터 말씀드리자면, '메인' 프로젝트에서 갖고 있는 submodule 의 정보는 '서브' 프로젝트(레포지토리) 자체가 아닌, '서브' 프로젝트의 '특정 commit-id' 를 갖고 있습니다. 

위에서 hugo 특성상 submodule을 활용한다고 말씀드렸습니다. 따라서 보통 아래와 같은 shell script를 활용합니다.

```bash
# 정적 사이트 생성
hugo -t PaperMod

# '서브' 프로젝트 commit & push
cd public
git add .
git commit -m ${commit-message}
git push ${origin} ${branch}

# '메인' 프로젝트 commit & push
cd ..
git add .
git commit -m ${commit-message}
git push ${origin} ${branch}
```

그림, 예시와 함께 문제 상황이 발생한 이유를 설명해보겠습니다. (아래 예시에서의 `push`는 말 그대로의 push를, `deploy`는 위 스크립트를 실행하는 것이라고 생각해주시면 되겠습니다. )

![](/assets/images/git-submodule-troubleshooting/2022-07-03-01-04-33.png)
1. 팀원 '갑'이 로컬에서 '메인' repository에 '서브' repository를 submodule로 추가하고, '부모'의 repository에 deploy 했습니다.
2. 그 순간, '메인' repository에서는 '서브' repository의 특정 commit-id(`SA`(sub-A)라고 하겠습니다)를 가져갑니다. (이 때 중요한 것은, '부모'의 repository에 push 할 때, '서브' repository는 push되지 않는다는 것입니다. '서브' repository는 별도로 push 과정을 거쳐야 하기 때문에 push가 아닌 deploy를 사용합니다.)
3. 다음으로, 팀원 '을'이 부모 repository를 clone 해옵니다. 이 때, '서브' repository 또한 `--recursive` 옵션을 통해 가져왔습니다. 해당 옵션을 통해 가져왔기 때문에, '서브' repository의 `SA` 커밋을 가져와서, HEAD로 가리킵니다.    
	3-1. 그런데 현재 '을'의 local에 있는 '서브'가 가리키고 있는 HEAD는 특정 브랜치가 아닙니다. 임시로 생성된 '커밋 브랜치'의 `SA` 커밋입니다.(커밋 브랜치는 임의로 붙인 이름입니다. 정확한 이름은 모르겠습니다.) 여기까지는 문제가 없습니다.

![](/assets/images/git-submodule-troubleshooting/2022-07-03-01-04-48.png)
4. 이 상태에서, '을'이 '서브'에 새로운 파일을 추가하고, commit 합니다.(해당 commit-id 를 `SB`라고 하겠습니다.)  
   4-1. 그런데 이 `SB` commit-id 는 '서브'의 특정 브랜치 다음에 생긴 브랜치가 아닙니다. 위에서 언급한 임시의 '커밋 브랜치' 다음에 위치합니다.  
5. 그리고 '을' 이 '메인' repository에 push합니다.   
   5-1. '메인' 입장에서는, '서브'의 commit-id가 `SB` 라는 정보를 가져갑니다. 즉, 가리키는 commit-id는 `SA`에서 `SB`로 바꿔치기됩니다.  
6. 이번에는 팀원 '병' 이 '메인' repository를 clone 해옵니다. 역시 마찬가지로, `--recursive` 옵션을 통해 가져왔고, '서브' repository의 `SB` commit을 가져오려하는 순간 문제가 발생합니다.  
7. 왜냐하면, '서브' repository의 그 어디에도 `SB` commit은 존재하지 않기 때문입니다.

그렇다면 "6~7번 사이에서 '서브' repository에 push 하면 되지 않나요?"(=7번에서 push가 아닌 deploy를 하면 되지 않나요?) 라고 의문을 제시할 수 있습니다만, 불가능합니다. 왜냐하면, 위 4번과 6번에서 말씀드렸다시피 commit의 위치가 특수한 곳에 존재하기 때문입니다. 따라서, push를 하려고 하면 다음과 같은 메시지를 볼 수 있습니다.

![](/assets/images/git-submodule-troubleshooting/2022-07-03-00-14-15.png)

이를 해결하기 위한 방법은 간단합니다. '서브' repository에 push하기 전에, 브랜치를 바꿔주면 됩니다. 즉, 위 쉘 스크립트를 수정하면 다음과 같이 됩니다.

```bash
# 정적 사이트 생성
hugo -t PaperMod

# '서브' 프로젝트 commit & push
cd public
git checkout ${branch} # <- 이 부분을 추가합니다.
git add .
git commit -m ${commit-message}
git push ${origin} ${branch}

# '메인' 프로젝트 commit & push
cd ..
git add .
git commit -m ${commit-message}
git push ${origin} ${branch}
```

## 여담
: github에서 clone 해올 때, 항상 특정 브랜치의 최신 커밋을 가져오도록 하면 좋을 것 같은데, 왜 이렇게 commit을 가져오도록 되어있는지 의문이 들었습니다. 그런데, 다시 생각해보면 이는 당연합니다.

> 말씀드렸던 대로, '메인' repository를 clone 할 때, 항상 '서브' repository의 최신 commit을 가져오게 된다고 가정해보겠습니다. '메인' repository를 개발한 사람이 정상적으로 잘 동작하는 것을 확인하고 push를 했는데, 시간이 지나 '메인' 에서 참조하고있는 '서브' repository가 업데이트 되었습니다. 그런데 '서브' repository 개발자의 실수로 버그가 있는 코드를 push했습니다.  
'메인' repository를 추가로 개발하려는 다른 사람이 clone 해왔는데, '메인' repository 또한 문제가 발생합니다. 왜냐하면, '서브' repository의 가장 최신 커밋을 가져왔기 때문에 '메인' 또한 버그가 발생했기 때문입니다.

우리가 Java 진영에서 흔히 사용하는 `gradle`이나 `maven`, 혹은 파이썬에서 `pip` 와 같은 툴들이 '특정 버전'을 관리하도록 한 이유도 이와 같겠죠. 또 다른 예시는 하단 reference 2번의 예시를 참고해주시면 되겠습니다. 이상으로 글을 마치겠습니다. 감사합니다.

# reference
1. [git submodule update needed only initially?](https://stackoverflow.com/questions/1992018/git-submodule-update-needed-only-initially)
2. [How can I specify a branch/tag when adding a Git submodule?](https://stackoverflow.com/questions/1777854/how-can-i-specify-a-branch-tag-when-adding-a-git-submodule)
   - This does make some sense when you think about it, though. Let's say I create repository *foo* with submodule *bar*. I push my changes and tell you to check out commit a7402be from repository *foo*.  
   Then imagine that someone commits a change to repository *bar* before you can make your clone.  
   When you check out commit a7402be from repository *foo*, you expect to get the same code I pushed. That's why submodules don't update until you tell them to explicitly and then make a new commit.
        
1. [git submodule 브랜치 추적](https://zeddios.tistory.com/718)
2. [git submodule 이해하기](https://ohgyun.com/711)
