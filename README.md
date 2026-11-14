# Diário de Classe — sistema semestral

Aplicativo Flutter para professores de cursos de graduação e cursos técnicos
gerenciarem turmas, alunos, notas e frequência.
Projeto realizado por alunos de Ciência da Computação do IFPA — Campus Tucuruí.

## Escopo atual

**Por enquanto, o sistema atende apenas aos cursos de graduação e aos cursos
técnicos.** O acompanhamento das turmas segue a organização semestral descrita
abaixo, com duas provas regulares e prova final quando necessária.

## Regra acadêmica

Cada turma representa um semestre e já possui exatamente dois bimestres. Cada
bimestre tem uma única prova, cujo nome pode ser alterado. Todas as notas ficam
entre 0 e 10; uma nota vazia é pendente, enquanto zero é uma nota válida.

- Média semestral: `(Prova 1 + Prova 2) / 2`.
- A média fica pendente até as duas provas serem lançadas.
- Média semestral maior ou igual à mínima: aprovado, sem prova final.
- Média semestral abaixo da mínima: prova final pendente.
- Após a prova final: `(média semestral + prova final) / 2`.
- O resultado deve atingir a mesma média mínima para aprovação após a final.
- A média mínima começa em 7,0 e pode ser alterada em **Perfil e regras**.
- Alterar ou remover notas e mudar a média mínima elimina a prova final quando
  o aluno fica dispensado ou passa a ter provas pendentes.
- A frequência sinaliza risco abaixo de 75%; ela não altera o resultado por nota.

A regra é centralizada em `lib/services/calculo_service.dart` e é compartilhada
pelo lançamento individual, prévia em lote, boletim, relatórios, CSV e PDF.

## Funcionalidades

- Cadastro, edição, exclusão e arquivamento de turmas.
- Cadastro de alunos com matrícula única por turma e observações.
- Busca e ordenação de alunos por nome, matrícula ou média final.
- Lançamento individual e em lote das duas provas e da prova final.
- Renomeação das provas e filtro de alunos com lançamentos pendentes.
- Frequência por aula, boletim individual e relatório semestral com gráfico.
- Exportação em CSV e PDF, com fontes locais e suporte a português.
- Backup e restauração completos em JSON.
- Tema claro, escuro ou conforme o sistema, selecionado no ícone de tema da
  tela inicial e salvo no aparelho; animações com redução de movimento.
- Estrutura para Android, iOS, Web/PWA, Windows, Linux e macOS.

## Identidade visual

A interface usa verde como cor principal e vermelho nos destaques, com fundos
neutros e tons adaptados aos temas claro e escuro. As referências institucionais
são o verde `#2F9E41`, o vermelho `#CD191E` e o preto, conforme o
[manual de marca disponibilizado pelo IFPA](https://www.ifpa.edu.br/documentos-institucionais/0000/logomarcas-2016/2638-manual-de-aplicacao-da-marca-dos-if-s).
Os tons de botões e textos foram ajustados para manter o contraste. A paleta
está centralizada em `lib/theme/app_palette.dart` e também é utilizada nos PDFs;
a inicialização web e o manifesto PWA seguem as mesmas cores.

O ícone do aplicativo utiliza a imagem fornecida para o projeto, preservada em
`assets/images/icone_diario_original.jpeg`. A mesma arte aparece na tela inicial,
na abertura web e nos PDFs. Os tamanhos para Android, iOS, macOS, Windows e PWA
podem ser gerados novamente a partir da raiz do projeto:

```sh
dart run tool/gerar_icones.dart
```

## Dados e backups

O sistema anterior de avaliações dinâmicas e recuperação por bimestre foi
removido. Seus cálculos, APIs e testes de compatibilidade não fazem parte da
aplicação. **Backups do formato anterior não são importados.**

O diário semestral usa a chave local `diario_classe_semestral_v1`, com
`sistema: "semestral"` e `versao: 5`. A chave do aplicativo anterior não é lida
nem sobrescrita: ao usar esta versão pela primeira vez, o novo diário começa
vazio. Não há conversão automática de notas antigas.

Os backups atuais preservam nomes personalizados das provas, notas, perfil,
arquivamento e frequência. Arquivos com versões desconhecidas, matrizes antigas,
quantidades desalinhadas ou notas inválidas são recusados integralmente.

As edições são revertidas em memória se a gravação falhar, preservando as
referências utilizadas pelas telas. Uma restauração só substitui os dados em
memória depois de salvar. Caso o diário semestral salvo não possa ser lido, a
aplicação abre a recuperação: é possível exportar o arquivo original, restaurar
um backup atual ou confirmar o início de um novo diário. A edição permanece
bloqueada enquanto os dados não forem recuperados.

Os dados ficam no aparelho; não há servidor nem sincronização automática.
Guarde backups para transferir o diário ou recuperar dados em outro dispositivo.

## Estrutura

- `lib/models/`: professor, turma, aluno, bimestre e registro de presença.
- `lib/services/`: cálculo semestral, persistência, arquivos, CSV e PDF.
- `lib/screens/`: telas de gerenciamento, notas, frequência e relatórios.
- `lib/theme/` e `lib/widgets/`: tema e componentes compartilhados.
- `assets/fonts/`: Roboto regular/negrito e respectiva licença Apache 2.0.
- `web/`: inicialização, manifesto e service worker do PWA.
- `test/`: regras semestrais, armazenamento, rollback, exportações e interface.

## Desenvolvimento

Requer Dart compatível com `^3.13.7` e Flutter compatível com as dependências
registradas em `pubspec.lock`.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Para gerar a versão web:

```sh
flutter build web --release --no-web-resources-cdn
```

O service worker armazena os arquivos para abertura offline após uma visita
online. As fontes usadas na interface e nos PDFs estão incluídas no aplicativo.
O funcionamento nativo e a distribuição exigem validação em cada plataforma;
o Android ainda usa identificador de exemplo e assinatura de desenvolvimento.
