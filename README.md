# Aevorath-RPG

RPG 2D por turnos inspirado em *Fear & Hunger*, no mundo de Aevorath.
Feito em **Godot 4.3** (GDScript). O jogo final é um `.exe` para Windows.

## Como jogar

- **Baixar o .exe pronto:** na aba *Actions* do GitHub, abra a última execução
  de "Testar e exportar .exe" e baixe o artefato `Aevorath-windows`.
- **Pelo Godot:** abra o Godot 4.3, importe a pasta do projeto e aperte F5.

Controles:

| Tecla | Ação |
| --- | --- |
| Setas / WASD | Andar no mapa |
| Z / Espaço / Enter | Interagir, confirmar |
| Setas + Enter ou mouse | Escolher ações na batalha |

## O que já existe

- **Mapa explorável** em grid de 32x32: a Cripta da Igreja do Décimo Dia, com
  placas de lore, o Altar dos Nove Sóis (descanso) e inimigos que perseguem a
  party quando ela chega perto.
- **Batalha por turnos com mira em membros**: cabeça, torso, braços e pernas.
  - Cabeça: difícil de acertar, decepar mata.
  - Braço da arma decepado enfraquece o ataque; sem os dois braços, só chutes.
  - Pernas decepadas: sem esquiva, age por último e não consegue fugir.
  - Membro decepado causa sangramento até usar bandagem ou Sigilo de Vida.
- **Party** com Iselde (Marcada/Mydrani, magia) e Doran (Cruzado desertor).
  Dano e membros perdidos continuam depois da batalha. O altar cura HP/MP,
  mas o que foi perdido não volta.
- **Inimigos**: Cruzado do Décimo Dia, Fiel Oco e Soldado de Sarnheim (arte do Carlos na batalha).

## Estrutura

```
scenes/            cenas (main, mundo, batalha)
scripts/main.gd    troca entre mapa e batalha
scripts/autoload/  Jogo: party, itens, progresso
scripts/mundo/     mapa em grid e dados dos mapas (texto)
scripts/combate/   Combatente (regras dos membros) e a batalha
scripts/data/      inimigos e habilidades
assets/            arte placeholder (32x32 no mapa; 128-256px na batalha)
tools/             gerador da arte placeholder (Python + Pillow)
tests/             teste automático headless
```

## Editando

- **Mapas:** `scripts/mundo/mapas.gd`, desenhados com caracteres (legenda no arquivo).
- **Inimigos:** `scripts/data/inimigos.gd`. As `regioes` são os retângulos de
  cada membro na imagem de batalha; ajuste se trocar a arte.
- **Arte:** substitua os PNGs em `assets/` mantendo nome e tamanho.
- **Testes:** `godot --headless res://tests/teste_auto.tscn`.
- **Exportar local:** instale os templates de exportação do Godot 4.3 e rode
  `godot --headless --export-release "Windows Desktop" build/Aevorath.exe`.
