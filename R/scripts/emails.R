pce <- read.csv('data/pessoaContratoEndereco.csv', stringsAsFactors = F)
m <- regexpr( '([a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\\])', as.character(pce$EMAIL))
mails <- regmatches(pce$EMAIL, m)

mailsLimpo <- mails[grep('oi.com|oi.net|oi.br|tem.com|tem.net|naotem@|naopossui|@nao.com|possui.com|@nt.com|ntem@|^nt@|^ntm@|@ntm.com|^sem@|@email.com|nãopossui', mails, invert =T )]


pceEmail <- pce[grep('naosei@|^nao@|xxx.com|oi.com|oi.net|oi.br|tem.com|tem.net|naotem@|naopos|@nao.com|possui.com|@nt.com|ntem@|^nt@|^ntm@|@ntm.com|^sem@|@email.com|nãopossui', pce$EMAIL, invert =T ),]

pceEmail <- pceEmail[grep('([a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\\])', pceEmail$EMAIL), ]

samplePce <- pceEmail[sample(1:nrow(pceEmail), 1000), c('CEP', 'Cidade', 'NOME', 'CGC_CPF','SEXO','EMAIL')]
write.csv(samplePce, 'data/sampleemail.csv',  row.names=F, na="",quote=F)