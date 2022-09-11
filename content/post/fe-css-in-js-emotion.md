안녕하세요, 모락 프론트엔드팀의 위니입니다 😄
<br>프로젝트를 시작하기 앞서, 모락 프론트엔드팀은 css in js 라이브러리 중 어떤 것을 선택할지 고민에 빠졌습니다.
<br>다양한 라이브러리가 있지만 그중 `styled-component`와 `emotion` 중 어떤 것을 사용할지 오랫동안 고민했고, 결론적으로는 `emotion`으로 작업을 하고 있습니다 🥳
<br>그렇다면 `styled-component`과 비교했을 때 `emotion`이 어떤 차이가 있었고, 결론적으로는 왜 `emotion`을 선택했는지 정리해보도록 하겠습니다. 

## <span style="color:#2AC1BC">비교 대상 설정: `styled-componet` & `emotion/style`<span style="color:#2AC1BC">
정확한 비교대상은 `styled-component`와 `emotion/style`로 설정했습니다. `emotion/style` 방식은 무엇일까요? 

emotion 사용방식은 크게 두가지(`emotion/css`, `emotion/styled`)로 나누어 볼 수 있습니다. 이 두가지를 비교해보자면 다음과 같습니다. 
- `emotion/css`
        
  이 방식은 개발자가 클래스명을 짓지 않아도 되니까 편하지만(개발자 친화적), 가독성이 떨어지고 스타일 컴포넌트가 생성되지 않아서 디버깅이 힘들 수 있다는 단점이 있습니다. 
- `emotion/styled`
   
  이 방식은 `styled-component`와 방식이 같습니다. 애초에  `emotion` 공식문서를 보면 `emotion/styled`는 `styled-component`의 방식에 큰 영감을 받아 만들어져있다고 되어있습니다.
  
  <img src="static/image1.png" width="500px">
  
  이러한 방식은 컴포넌트를 생성하기 때문에, 리액트 디버깅이 편합니다. 
  (여담이지만 2022년 9월 기준, `emotion/styled`가 `styled-component`보다 npm 다운 수가 더 높네요!)
  
  <img src="static/image2.png" width="500px">

            
모락 프론트엔드 팀에서는 이 두가지의 방식 중, 스타일 컴포넌트를 생성하는 `emotion/styled`의 이점을 더 크게 봤습니다. 
따라서, `styled-component`와 비교할 대상은 `emotion/styled`로 결정했습니다. 
**+)** 추가적으로 실제 `emotion/css` 방식으로 코드를 작성했을 때 인라인 방식으로 css를 작성하다보니 코드가 매우 늘어지고 지저분해짐을 느꼈어요 😅 즉, 가독성의 측면에서도 `emotion/styled` 이 우세하다고 판단했습니다. 

## <span style="color:#2AC1BC">성능 비교<span style="color:#2AC1BC"> 
### 성능: 용량 비교 
라이브러리 번들 사이즈 사이트에서 비교한 결과, 결론은 용량은 매우 비슷합니다. (emotion이 1.1kB 더 작습니다.)

- `styled-component` (33.5kB)
<img src="static/image3.png" width="500px">
- `emotion/style` (21.2kB + 11.2kB = 32.4kB)
`emotion/styled` 쓴다고 가정하면, 보통 두가지 라이브러리(`emotion/styled`와 `emotion-react`를 함께 사용합니다. 따라서 두가지 라이브러리를 더한 용량을 측정합니다. emotion 라이브러리 종류는 [여기서 확인하세요!](https://emotion.sh/docs/package-summary))  
<img src="static/image4.png" width="500px">
<img src="static/image5.png" width="500px">


### 성능: 속도 비교 
결론적으로 유의미한 속도 차이가 있지 않습니다. 
- 다양한 참고자료를 통해 살펴본 결과, `emotion`이 아주 조금 더 빠릅니다. 
- 하지만, `styled-component` v5에서는 `styled-component`가 더 빠르다는 결과가 있습니다. 
    - [참고](https://styled-components.com/releases#v5.0.0)
    - [참고](https://medium.com/styled-components/announcing-styled-components-v5-beast-mode-389747abd987)
- 또한 속도는 라이브러리 버전에 따라 달라질 수 있습니다. 

### 성능: 결론 
성능의 용량과 속도 면에서, 유의미한 차이가 없습니다.  


## <span style="color:#2AC1BC">성능에서 유의미한 차이가 없다... 그럼 각각을 골랐을 때의 이점을 생각해보자!<span style="color:#2AC1BC">
### 1. `styled-component`사용
- 사용해 본 라이브러리이기때문에, 사용법이 익숙합니다. 
어차피 두개의 라이브러리 성능이 비슷하다면, 사용법이 익숙한 것을 사용하면 개발 생산성에 영향을 줄 수 있기 때문에 이점이 될 수 있을거라고 생각했습니다. 
- `emotion/style`이 `styled-components`의 영감을 받아서 만들어진 라이브러리이기 때문에 더 잘 만들지 않았을까라는 살짝의 뇌피셜도 있었습니다. (정말 그랬을까요?🤔 글 후반을 참고해주세요!) 
  
### 2. `emotion` 사용 
- `styled-component`보다 더 다양한 기능이 있기 때문에, 확장성에 좋습니다. 
`emotion`은 `emotion/style`을 통해 `styled-component` 방식을 그대로 사용할 수도 있지만 다른 방식을 통해 더 다양하게 사용할 수도 있어서 확장성이 더 뛰어납니다. 
- npm 다운 수가 더 높습니다. 하지만 이는 명확한 이점이 될수는 없을 것 입니다. 더 hot한 라이브러리를 사용해서 기분은 좋을 수 있겠네요 😄 
<img src="static/image6.png" width="500px">


## <span style="color:#2AC1BC">결론: `emotion/styled`를 사용한다!<span style="color:#2AC1BC">
<img src="static/image7.png" width="500px">

모락 프론트엔드 팀에서는 스타일 라이브러리를 정하기 위한 두근거리는 투표를 진행했습니다. 
결론적으로는... emotion의 승리! 🥳 emotion을 선택한 근거는 다음과 같습니다. 

- **확장성**을 생각하여 emotion을 선택했습니다. 
    - 추후에, 성능 개선이나 다른 방식으로 `emotion/css` 방식을 추가 적용할 가능성이 있다고 생각하여, 더 많은 기능을 제공하는 `emotion`을 선택했습니다. 
- 또한, `emotion/style`이 `styled-components`의 영감을 받아서 만들어진 라이브러리이기 때문에 더 잘 만들지 않았을까라는 살짝의 뇌피셜도 있었습니다 😄 (선택 당시에는 이런 생각을 했었는데, 사용해보니 별 차이가 없고, 거의 똑같습니다.)


지금까지 모락 프론트엔드 팀이 css in js 라이브러리로 `emotion`을 사용한 이유를 `styled-component`와 비교하여 설명드렸습니다. 
프로젝트 과정에서 `emotion`을 사용하면서 느끼는 장단점이 있다면, 계속해서 업데이트하도록 하겠습니다. 감사합니다 :)
    
---
**참고 자료**
- 용량 비교(라이브러리 번들 사이즈 측정)
[https://bundlephobia.com/](https://bundlephobia.com/)
    
- npm trend
[https://npmtrends.com/@emotion/styled-vs-emotion-vs-styled-components](https://npmtrends.com/@emotion/styled-vs-emotion-vs-styled-components)
    
- [https://velog.io/@bepyan/styled-components-과-emotion-도대체-차이가-뭔가](https://velog.io/@bepyan/styled-components-%EA%B3%BC-emotion-%EB%8F%84%EB%8C%80%EC%B2%B4-%EC%B0%A8%EC%9D%B4%EA%B0%80-%EB%AD%94%EA%B0%80)
