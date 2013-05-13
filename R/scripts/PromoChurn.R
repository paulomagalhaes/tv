 	

library(RJDBC)

drv <- JDBC("oracle.jdbc.driver.OracleDriver",
            "/Users/paulomagalhaes/Projects/OiTv/ojdbc6.jar")
conn <- dbConnect(drv, "jdbc:oracle:thin:@oracle01:1521:objoi02", "oidth0205", "oidth0205")

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
	   Statusdocontrato(c.status) cStatus,
       c.data_inicio cInicio,
       c.data_fim cFim,
       p.\"Data Incício\" pInicio,
       p.\"Data Fim\"     pFim
	FROM   promocao_aplicacao pa,
       r_promocao p,
       contrato_assinante c
	WHERE  p.\"Categoria\" = 'Retencao'
       AND p.id = pa.id_promocao
       AND c.id = id_contrato")

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