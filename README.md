
## 1. 프로젝트를 가져오는 방법

```bash
git clone https://github.com/morak-morak/hugo-blog.git --recursive
```

## 2. 블로그에 글을 작성하는 방법
A. `content/post` 디렉토리 하위에 마크다운 형식으로 포스트를 작성한다.  
B. `sh local.sh`(3번 항목)을 이용해 작성 내용을 확인한다. (localhost:1313)
C. 작성된 글의 헤더에 `draft: true` 항목을 false로 바꾼다.
D. `sh deploy.sh "commit message"` 명령어를 실행해 배포를 완료한다.
