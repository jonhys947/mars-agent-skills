---
name: revisao-pr
description: 'Revisar Pull Requests de forma incremental, verificável e conservadora, com foco em:


  - firmware embarcado;

  - protocolos;

  - documentação técnica;

  - contratos binários;

  - hardware/software integration;

  - CI;

  - correções cirúrgicas antes do merge.'
---

## Finalidade

Revisar Pull Requests de forma incremental, verificável e conservadora, com foco em:

- firmware embarcado;
- protocolos;
- documentação técnica;
- contratos binários;
- hardware/software integration;
- CI;
- correções cirúrgicas antes do merge.

A skill deve trabalhar sobre o **estado real do repositório**, nunca apenas sobre o relato do agente que implementou o PR.

O objetivo não é reimplementar o PR inteiro.

O objetivo é:

1. confirmar o que realmente foi publicado;
2. comparar com a tarefa que originou o PR;
3. identificar lacunas funcionais, normativas, de segurança ou documentação;
4. corrigir apenas o necessário;
5. executar/revisar os gates;
6. só então recomendar ou realizar o merge, se autorizado.

---

# Princípio central

Sempre separar:

```text
O QUE O AGENTE DISSE QUE FEZ
```

de:

```text
O QUE ESTÁ REALMENTE NO GITHUB
```

Um PR só pode ser considerado revisado depois de confirmar:

- base;
- head;
- commits;
- arquivos alterados;
- código publicado;
- documentação publicada;
- testes;
- CI;
- estado do PR;
- mergeability.

Nunca assumir que uma tarefa descrita como concluída chegou ao repositório.

---

# 1. Entrada mínima

A revisão deve aceitar pelo menos uma destas entradas:

```text
PR #N
```

ou:

```text
URL do Pull Request
```

Informações adicionais úteis, mas não obrigatórias:

```text
SHA base esperado
SHA head esperado
prompt original
relatório do agente
CI informado
restrições de escopo
```

Se o usuário fornecer um relatório do agente, tratá-lo como:

```text
alegação a verificar
```

e não como fonte de verdade.

---

# 2. Fonte de verdade

Para estado de implementação, usar prioritariamente:

```text
GitHub remoto
```

Conferir diretamente:

- PR;
- branch;
- commits;
- diff;
- arquivos;
- workflows;
- jobs;
- código na head do PR.

Para contratos/normas do projeto, usar:

```text
documentação normativa vigente do próprio repositório
```

Exemplos:

- source of truth;
- protocolo;
- CAN map;
- payload spec;
- hardware reference;
- schemas;
- decisão arquitetural;
- documentação Web;
- decision log.

Nunca substituir documento vigente por memória do modelo quando o arquivo está disponível.

---

# 3. Primeira verificação do PR

Antes de analisar código, registrar:

```text
PR:
Título:
Estado:
Draft:
Base branch:
Base SHA:
Head branch:
Head SHA:
Mergeable:
Número de commits:
Número de arquivos alterados:
CI mais recente:
```

Confirmar se:

```text
base SHA == base esperada
```

quando uma base foi definida pela tarefa.

Se a base estiver errada, interromper a aprovação e explicar a divergência.

Não continuar assumindo que o PR representa corretamente a sequência planejada.

---

# 4. Verificar se o trabalho realmente foi publicado

Quando o agente aparentar ter travado, encerrado abruptamente ou parado em uma etapa intermediária:

não assumir que o trabalho foi perdido.

Primeiro verificar:

```text
head atual do PR
commits posteriores
novos arquivos
novo CI
descrição do PR
estado draft/ready
```

Comparar:

```text
head anteriormente conhecido
        ↓
head atual
```

Usar comparação de commits para descobrir o delta publicado depois da última revisão.

Classificar:

```text
PUBLICADO
FEITO APENAS LOCALMENTE
NÃO IMPLEMENTADO
INDETERMINADO
```

Nunca pedir ao usuário para repetir trabalho antes dessa verificação.

---

# 4.1 Regra obrigatória para “agente travado”

Quando houver qualquer sinal de travamento, interrupção abrupta ou parada em etapa intermediária:

1. **Não reiniciar a tarefa.**
2. **Não pedir ao usuário para repetir o trabalho.**
3. **Não assumir que o trabalho foi perdido.**
4. A primeira ação operacional deve ser comparar:

```text
último SHA conhecido
        vs
head atual do PR
```

5. Se `head atual != último SHA conhecido`:
   - listar commits entre os dois;
   - listar arquivos/diff do delta;
   - verificar CI correspondente ao head atual;
   - classificar o que já está `PUBLICADO`;
   - revisar somente o delta adicional;
   - completar apenas o que realmente faltar.

6. Se `head atual == último SHA conhecido`:
   - verificar se houve commit em outra branch/fork;
   - verificar se o PR foi atualizado;
   - verificar se há CI novo;
   - só então classificar como `NÃO PUBLICADO` ou `INDETERMINADO`.

7. Nunca tratar “interface travou” como sinônimo de “trabalho não publicado”.

Comandos conceituais úteis:

```text
git fetch
git log --oneline <ultimo_sha_conhecido>..<head_atual>
git diff --stat <ultimo_sha_conhecido>..<head_atual>
```

Ou equivalente via API do GitHub:

```text
compare <ultimo_sha_conhecido>...<head_atual>
```

Justificativa empírica: foi exatamente essa verificação que evitou refazer quase todo o PR #21 — o agente tinha efetivamente publicado a maior parte do trabalho (commits, arquivos e CI) antes de a interface ficar presa. Reiniciar a tarefa nesse cenário teria gerado retrabalho massivo e risco de regressão.

---

# 5. Revisão por delta

Se o PR já foi revisado anteriormente, não reler tudo sem necessidade.

Comparar:

```text
último head aprovado
        ↓
novo head
```

Revisar prioritariamente:

- arquivos modificados no novo delta;
- testes adicionados;
- documentação alterada;
- mudanças em gates;
- mudanças em permissões;
- mudanças em estados;
- mudanças em segurança/fail-safe.

Depois confirmar que o novo delta não quebrou pressupostos já aprovados.

Isso mantém a revisão incremental e reduz ruído.

---

# 6. Revisão contra o prompt original

Extrair do prompt original:

```text
objetivos
itens obrigatórios
itens proibidos
gates
documentação exigida
condições de conclusão
```

Montar mentalmente ou explicitamente uma matriz:

```text
requisito | estado | evidência
```

Estados recomendados:

```text
IMPLEMENTADO
IMPLEMENTADO PARCIALMENTE
NÃO IMPLEMENTADO
BLOQUEADO INTENCIONALMENTE
GATE FÍSICO
FORA DE ESCOPO
```

Não considerar um requisito implementado apenas porque existe código relacionado.

Verificar a integração real.

---

# 7. Revisão normativa

Para qualquer alteração de protocolo/configuração:

confirmar contra os documentos normativos vigentes:

- IDs;
- DLC;
- offsets;
- endian;
- flags;
- sentinelas;
- periods;
- freshness;
- producers;
- consumers;
- permissions;
- schema revisions;
- CRC;
- generations;
- persistence semantics;
- deduplication;
- reset/session behavior.

Se o PR altera comportamento normativo sem que o prompt autorize mudança normativa:

classificar como bloqueador.

Não “consertar” o documento normativo para justificar uma implementação divergente.

---

# 8. Revisão de segurança e fail-closed

Em firmware, procurar especialmente situações nas quais uma condição é verificada apenas na entrada, mas pode mudar durante a operação.

Exemplo geral:

```text
gate seguro na entrada
        ↓
estado muda depois
        ↓
operação continua indevidamente autorizada
```

Sempre perguntar:

- o gate continua sendo válido durante toda a operação?
- uma condição de segurança pode mudar depois da entrada?
- timeout revoga autorização?
- reset revoga autorização?
- perda de comunicação revoga autorização?
- START/ignição/enable pode mudar durante CONFIG?
- staging é abortado?
- imagem parcial pode ficar ativa?
- valor stale pode continuar sendo usado?
- última leitura válida fica indevidamente “sticky”?

Preferir:

```text
fail-closed
```

A perda de informação, autorização ou condição de segurança deve normalmente levar a:

```text
INVALID
DENIED
UNKNOWN
OFF
ABORT
```

e não à manutenção silenciosa do último valor válido.

---

# 9. Revisão de máquina de estados

Para fluxos como:

```text
BOOT
RUN
CONFIG
ERROR
SAFE
```

verificar:

- condições de entrada;
- condições de saída;
- transições proibidas;
- timeout;
- eventos assíncronos;
- reboot;
- erro;
- perda de storage;
- perda de CAN;
- eventos físicos.

Exigir testes de transição quando a lógica for relevante para segurança ou persistência.

---

# 10. Revisão de concorrência

Se houver:

- task HTTP;
- loop principal;
- ISR;
- CAN;
- NVS;
- buffers compartilhados;
- snapshots;

verificar quem é o **owner da mutação**.

Preferir arquitetura:

```text
task externa
→ enfileira comando
→ loop/owner principal
→ altera estado
```

Evitar:

```text
handler HTTP
→ altera diretamente store/runtime compartilhado
```

Verificar:

- locks;
- critical sections;
- atomic swap;
- staging separado do ativo;
- vida útil de buffers;
- ponteiros transitórios;
- acesso simultâneo.

---

# 11. Revisão de persistência

Para objetos persistentes verificar:

```text
imagem inicial
staging
validate
SAVE
SAVE_AND_APPLY
generation
CRC
write
readback
recovery
fallback
corruption
reboot
```

Confirmar a semântica normativa de:

```text
SAVE
```

versus:

```text
SAVE_AND_APPLY
```

Não inferir.

Testar:

- slot novo válido;
- slot novo corrompido;
- slot anterior válido;
- ambos inválidos;
- NVS ausente;
- reboot;
- generation wrap;
- imagem idêntica;
- commit rejeitado;
- readback divergente.

---

# 12. Revisão de permissions

Separar sempre:

```text
capability
permission
storage availability
authentication
configuration mode
physical presence
```

Esses conceitos não são equivalentes.

Exemplo incorreto:

```text
NVS disponível
→ escrita autorizada
```

Exemplo correto:

```text
NVS disponível
AND
objeto suporta escrita
AND
requisição autenticada
AND
modo CONFIG ativo
AND
intertravamentos válidos
→ escrita autorizada
```

Se existirem interfaces diferentes, separar suas permissões.

Exemplo:

```text
Web local: writable
CAN externo: read-only
```

Não promover permissions CAN apenas porque o backend local é writable.

---

# 13. Revisão Web

Para Web embarcada verificar:

- autenticação;
- separação WPA × HTTP auth;
- modo CONFIG;
- timeout;
- ausência de credenciais em HTML/JS/JSON/log;
- GET sem efeito colateral;
- handlers mutáveis autenticados;
- fila HTTP → owner principal;
- readback;
- operation tracking;
- erros HTTP;
- ausência de handlers falsos.

Para APIs de configuração:

```text
draft
→ validate
→ save/apply
→ verify
→ readback
→ success
```

Sucesso só deve ser declarado após confirmação do estado efetivo.

---

# 14. Revisão de CAN

Para cada novo frame ou consumidor alterado verificar:

```text
ID
DLC
producer
consumer
period
freshness
seq
flags
invalid values
stale behavior
reset/session behavior
```

Para `seq`, conferir explicitamente:

```text
primeiro frame
delta 1..127
delta 0
delta 128..255
wrap 255→0
reset/new session
```

Duplicata não deve renovar freshness quando a norma não permite.

Frame antigo não deve substituir estado novo.

---

# 15. Revisão de sensores

Separar:

```text
driver respondeu
IC presente
canal presente
sensor presente
leitura realizada
amostra plausível
amostra válida
sensor calibrado
fonte operacional
```

Nunca usar:

```text
analogRead retornou
```

como prova de:

```text
sensor fisicamente válido
```

Da mesma forma:

```text
ACK I²C
```

não prova que o sensor externo existe ou está corretamente conectado.

Manter gates físicos explícitos.

---

# 16. Revisão de testes

Não aceitar apenas:

```text
build passou
```

como prova funcional.

Conferir separadamente:

```text
compile
unit tests
host tests
protocol vectors
ASan
UBSan
integration tests
physical bring-up
```

Se teste físico não foi realizado:

registrar exatamente:

```text
NÃO EXECUTADO — GATE FÍSICO
```

Nunca transformar isso em “passou”.

---

# 17. Revisão do CI

Conferir o run correspondente ao **head atual**, não um CI antigo.

Verificar individualmente todos os jobs.

Exemplo:

```text
master
cluster_7
aux_display
climate
protocol-host-tests
```

Se um novo commit documental ou de teste alterar o head, um CI antigo deixa de ser o CI final.

Esperar ou verificar o novo run antes de declarar:

```text
5/5 verde
```

---

# 18. Mudanças durante a revisão

Se a revisão encontrar um problema simples e claramente dentro do escopo:

pode corrigir diretamente no mesmo PR.

Critérios:

- problema comprovado;
- correção pequena;
- sem decisão arquitetural nova;
- sem nova revisão normativa;
- sem ampliar escopo.

Exemplos adequados:

```text
gate de segurança ausente
teste faltante
rota incorreta
doc desatualizada
flag errada
timeout não revogando staging
```

Exemplos que exigem nova decisão/trabalho:

```text
novo schema
novo CAN ID
mudança de wire
mudança de arquitetura
novo hardware
novo recurso
```

---

# 19. Após uma correção

Sempre:

1. confirmar novo head;
2. confirmar que a mudança chegou ao PR;
3. verificar novo CI;
4. revisar os testes específicos;
5. atualizar documentação viva se necessário;
6. atualizar descrição do PR se ela contém SHA/CI antigo.

Não deixar descrição dizendo:

```text
head final = SHA antigo
CI final = run antigo
```

---

# 20. Documentação

Documentação deve refletir o firmware real.

Verificar especialmente textos como:

```text
aguardando CI
não implementado
read-only
pendente
fail-closed
```

quando a implementação mudou.

Não alterar documentação normativa congelada apenas para registrar estado de implementação.

Preferir atualizar:

```text
FIRMWARE_STATUS
PROTOCOL_IMPLEMENTATION
WEB_CONFIGURATION_SPEC
DECISION_LOG
```

conforme a natureza da mudança.

---

# 21. Revisão de escopo

Antes da aprovação final, confirmar explicitamente que o PR não introduziu:

- arquivos fora do escopo;
- alterações normativas não autorizadas;
- refactors oportunistas;
- novas dependências desnecessárias;
- mudanças de pinagem;
- mudanças de IDs;
- mudanças de schema;
- capabilities não solicitadas;
- habilitação prematura de hardware.

Pesquisar também por artefatos legados que deveriam ter sido removidos.

---

# 22. Critério de aprovação

Um PR pode ser considerado pronto quando:

```text
requisitos do prompt satisfeitos
+
normas respeitadas
+
nenhum bloqueador de software conhecido
+
CI do head atual verde
+
documentação coerente
+
gates físicos explicitamente classificados
+
escopo preservado
```

Testes físicos pendentes podem não impedir merge quando:

- o software foi deliberadamente projetado fail-closed;
- a tarefa permite implementação antes do bring-up;
- documentação deixa o gate físico explícito;
- nenhuma fonte/recurso é promovida como fisicamente válida.

---

# 23. Merge

Nunca realizar merge automaticamente durante uma revisão.

Só fazer merge se o usuário ordenar explicitamente algo como:

```text
faça o merge
pode mergear
publique o merge
```

Antes do merge, verificar novamente:

```text
PR aberto
head esperado
mergeable
CI final
```

Usar proteção por SHA esperado quando disponível.

Após o merge confirmar:

```text
PR merged=true
merge commit SHA
main SHA
main == merge commit
```

Relatar o merge somente depois dessa confirmação.

---

# 24. Nunca fazer

Não:

- confiar apenas no texto do agente;
- assumir que código local foi publicado;
- aprovar CI de head antigo;
- misturar próximo prompt no PR atual;
- “aproveitar” para refatorar;
- inventar norma ausente;
- inferir hardware não confirmado;
- tratar build como bring-up;
- tratar teste sintético como teste físico;
- habilitar writer apenas porque backend existe;
- manter último valor válido quando a norma exige invalid/stale;
- mergear sem ordem explícita.

---

# 25. Ordem de atenção

Durante a revisão, priorizar:

```text
1. segurança/fail-safe
2. violações normativas
3. corrupção/persistência
4. concorrência
5. estado/freshness
6. permissions/autorização
7. integração funcional
8. testes
9. documentação
10. estilo/refactor
```

Problema de estilo não deve obscurecer bug funcional.

---

# 26. Formato do relatório de revisão

Usar um relatório curto e objetivo.

Modelo:

```text
PR #N revisado no head <SHA>.

Estado:
- base:
- head:
- aberto/fechado:
- draft:
- mergeable:
- CI:

Confirmado:
- ...
- ...
- ...

Problemas encontrados:
1. ...
2. ...

Correções realizadas:
- ...
- ...

Gates:
- software:
- físico:
- normativo:

Conclusão:
PR pronto para merge / ainda bloqueado por ...
```

Se nenhum problema for encontrado:

```text
Não encontrei bloqueador de software adicional.
```

Evitar declarações genéricas como:

```text
parece bom
provavelmente está certo
```

---

# 27. Quando o agente travou

Procedimento obrigatório:

```text
1. Comparar último SHA conhecido com o head atual do PR.
2. Se o head mudou, listar commits/diff/CI do delta publicado.
3. Só depois ler PR, commits posteriores e novo CI.
4. Revisar somente o delta adicional.
5. Identificar o que realmente ficou faltando.
6. Completar apenas o restante.
7. Não reiniciar a tarefa.
8. Não pedir ao usuário para repetir o trabalho.
```

Muitas vezes o agente pode ter:

```text
feito
commitado
publicado
aberto PR
disparado CI
```

antes de a interface parecer travada.

A pergunta correta não é:

```text
“O que falta implementar?”
```

e sim:

```text
“O que já foi publicado desde o último SHA conhecido,
e qual é o delta real ainda não revisado?”
```

Essa inversão de pergunta é o que evita retrabalho e preserva a natureza incremental da revisão.

---

# 28. Filosofia da skill

A revisão deve ser:

```text
incremental
evidenciada
fail-closed
cirúrgica
reprodutível
conservadora
```

A pergunta principal nunca é:

```text
“O agente disse que terminou?”
```

A pergunta correta é:

```text
“O repositório, no head atual, implementa exatamente o que foi pedido,
respeita os contratos vigentes e passou pelos gates correspondentes?”
```

Somente depois disso o PR está pronto.
```
