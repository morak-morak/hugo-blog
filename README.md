
## 1. 프로젝트 가져오기

```bash
git clone https://github.com/morak-morak/hugo-blog.git --recursive
```

## 2. 블로그 글 추가하기
(글 작성 이후)
```bash
sh deploy.sh "commit message"
```

## 3. 정적 사이트 생성
**remote repository와 conflict날 수 있으니 반드시 public 디렉토리에서 pull을 한번 할 것**  
hugo -t PaperMod

## 4. 로컬 서버 
**remote repository와 conflict날 수 있으니 반드시 public 디렉토리에서 pull을 한번 할 것**
```bash
hugo server -D 
```
-> localhost:1313

