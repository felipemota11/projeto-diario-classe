# Diário de Classe

Aplicativo Flutter para professores gerenciarem turmas, alunos, avaliações, notas e relatórios.

Projeto realizado por alunos de Ciência da Computação (IFPA – Campus Tucuruí).

## Funcionalidades

- Cadastro, edição e exclusão de múltiplas turmas.
- Turmas ativas e arquivadas, sem perder o histórico.
- Cadastro, edição e exclusão de alunos por matrícula, com observações.
- Busca por nome/matrícula e ordenação dos alunos.
- Cadastro, edição e exclusão de bimestres.
- Avaliações dinâmicas por bimestre: adicionar, renomear e excluir avaliações.
- Lançamento de notas em lote para todos os alunos do bimestre.
- Lançamento, alteração e exclusão de notas e recuperações.
- Controle de frequência por aula, com percentual de presença por aluno.
- Boletim individual do aluno com exportação em PDF.
- Relatórios da turma com exportação em PDF e CSV.
- Cálculo de médias, recuperação e situação acadêmica.
- Média mínima para aprovação configurável no perfil.
- Filtros de alunos por situação: aprovados, pendentes e abaixo da média.
- Backup completo dos dados em JSON e restauração de arquivo.
- Tema claro/escuro e interface com animações, seguindo o sistema.
- Funcionamento como PWA instalável, com cache offline.
- Suporte a Android, iOS, Web, Linux, macOS e Windows.

## Regra de cálculo

- A média das avaliações é calculada somente quando todas as avaliações
  cadastradas no bimestre tiverem nota lançada.
- A recuperação é aplicada quando a média das avaliações for menor que a
  média mínima configurada no perfil.
- A média final com recuperação é `(média das avaliações + recuperação) ÷ 2`.
- A média mínima para aprovação começa em **7,0** e pode ser alterada em
  **Perfil e regras**.


## Estrutura do projeto

```text
lib/
├── main.dart
├── models/
│   ├── aluno.dart
│   ├── bimestre.dart
│   ├── professor.dart
│   ├── registro_presenca.dart
│   └── turma.dart
├── screens/
│   ├── alunos_screen.dart
│   ├── avaliacoes_screen.dart
│   ├── backup_screen.dart
│   ├── boletim_screen.dart
│   ├── frequencia_screen.dart
│   ├── inicio_screen.dart
│   ├── lancamento_lote_screen.dart
│   ├── notas_screen.dart
│   ├── perfil_screen.dart
│   ├── relatorios_screen.dart
│   └── turmas_screen.dart
├── services/
│   ├── arquivo_service.dart
│   ├── armazenamento_service.dart
│   ├── calculo_service.dart
│   ├── exportacao_service.dart
│   └── pdf_service.dart
├── theme/
└── widgets/
```


<p align="center">
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/flutter/flutter-original.svg" width="120" alt="Flutter" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/dart/dart-original.svg" width="120" alt="Dart" />
</p>
