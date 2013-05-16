 	

library(RJDBC)

drv <- JDBC("oracle.jdbc.driver.OracleDriver",
            "/Users/paulomagalhaes/Projects/tv/ojdbc6.jar")
conn <- dbConnect(drv, "jdbc:oracle:thin:@oracle01:1521:objoi02", "", "")
promo.ret <- dbGetQuery(conn, 
"SELECT /*+ ORDERED  use_nl(p d a) */
      c.id,
      Statusdocontrato(c.status) cStatus,
      c.data_inicio cInicio,
      c.data_fim cFim,
      min(d.data_inicio) pInicio,
      max(d.data_fim)  keep (dense_rank first order by d.data_fim desc nulls first)
FROM   promocao p,
      desconto d,  
       assinatura a,
       contrato_assinante c
WHERE  d.id_promocao = p.id
       AND p.categoria = 'Retencao'
       and a.id_contrato = c.id
       and a.id = d.id_assinatura
group by       c.id,
       c.data_inicio,
       c.data_fim,
        d.id_promocao,
        Statusdocontrato(c.status)")

promo.freq <- dbGetQuery(conn, 
"SELECT c.id, c.data_inicio, c.data_fim, count(*) promocoes
FROM   promocao_aplicacao pa,
       r_promocao p,
       contrato_assinante c
WHERE p.\"Categoria\" = 'Retencao'
       AND p.id = pa.id_promocao
       AND c.id = id_contrato       
GROUP BY c.id, c.data_inicio, c.data_fim")

promo.ret <- dbGetQuery(conn,
	"SELECT c.id,
      pa.id paid,
      Statusdocontrato(c.status) cStatus,
      c.data_inicio cInicio,
      c.data_fim cFim,
      d.data_inicio pInicio,
      d.data_fim pFim
      FROM promocao_aplicacao pa, r_promocao p, contrato_assinante c, desconto d
      WHERE p.\"Categoria\" = 'Retencao'
      AND p.id = pa.id_promocao
      AND c.id = id_contrato)
      AND d.id_promocao = p.id")

save(promo.ret, file=file.path('/Users/paulomagalhaes/Projects/OiTv/R/data', 'promo.ret.RData'))

result <- t(as.matrix(character(3)))

for (i in 1:nrow(promo.ret)){
	pDays <- seq(as.Date(promo.ret[i, 'PINICIO']), if(is.na(as.Date(promo.ret[i, 'PFIM']))) Sys.Date() else as.Date(promo.ret[i, 'PFIM']), by="1 month")
	result <- rbind (result, cbind(promo.ret[i,'ID'], promo.ret[i,'CSTATUS'], pDays))
	if (i %% 1021 == 0) {print(i)}
}

for (x in promo.ret[1:10,]){
	print(x['PINICIO'])
}

extendDF <- function(x) {
    foo <- function(i, z) {
        freq <- seq(as.Date(z[i, 'PINICIO']), if(is.na(as.Date(z[i, 'PFIM']))) Sys.Date() else as.Date(z[i, 'PFIM']), by="1 month")
        times <- length(freq)
        out <- data.frame(freq,
                          rep(z[i, 'ID'], times),
                          rep(z[i, 'CSTATUS'], times))
        #names(out) <- names(z)
        if (i %% 1021 == 0) {print(i)}
        out
    }
    out <- lapply(seq_len(nrow(x)), FUN = foo, z = x)
    do.call("rbind", out)
}


seq(as.Date(promo.ret[i, 'PINICIO']), if(is.na(as.Date(promo.ret[i, 'PFIM']))) Sys.Date() else as.Date(promo.ret[i, 'PFIM']), by="1 month")




