library(RJDBC)
library(tm)

drv <- JDBC("oracle.jdbc.driver.OracleDriver",
            "/Users/paulomagalhaes/Projects/tv/ojdbc6.jar")
conn <- dbConnect(drv, "jdbc:oracle:thin:@oracle01:1521:objoi02", "oidth0205", "oidth0205")

notas <- dbGetQuery(conn, 
" SELECT id_objeto,
       observacao_usuario
FROM   nota n,
       acao a
WHERE  n.id_acao = a.id
       AND a.is_textual_usuario = 'T'  ")


save(notas, file=file.path('data', 'notasAtendimento.RData'))

replaceDiacritics <- function(x){
    tmp <- iconv(x, from="UTF8", to ="ASCII//TRANSLIT")
    gsub("[^[:alnum:][:space:]]", "", tmp)
}
notas$observacao <- sapply(notas$OBSERVACAO_USUARIO, replaceDiacritics)
ctrl <- list(removePunctuation = list(preserve_intra_word_dashes = TRUE), stopwords = c(stopwords(kind="portuguese"), replaceDiacritics(stopwords(kind="portuguese"))))
oi.tdm <- TermDocumentMatrix(Corpus(VectorSource(notas$observacao)), control=ctrl) 	
all.sorted <-  sort(rowSums(as.matrix(oi.tdm)),decreasing=TRUE)
oi.d <- data.frame(word = names(all.sorted),freq=all.sorted)
pal2 <- brewer.pal(8,"Dark2")
wordcloud(oi.d$word,oi.d$freq, scale=c(8,.7),min.freq=3, max.words=Inf, random.order=FALSE, rot.per=.15, colors=pal2)

m <- regexpr( '([a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\\])', pce$EMAIL)
mails <- regmatches(m, pce$EMAIL)




