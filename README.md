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

- **Mapa explorável** em grid de 32x32: a Prisão da Igreja do Décimo Dia.
  O jogo começa numa cela. O encapuzado de olhos vermelhos entrega a chave das
  celas e uma Pedra Solar; Iselde, presa em outra cela, entra na party.
  Há esqueletos e placas com lore, o Altar dos Nove Sóis (descanso) e inimigos
  que perseguem a party quando ela chega perto. A escada no canto é o fim da demo.
- **Relógio e luz**: cada passo gasta 2 minutos. A magia só funciona sob a luz
  do sol ou da lua (a lua reflete o sol).
  - Feixes de luz entram pelas grades do teto: dentro deles a magia funciona.
  - No escuro, cada magia gasta 1 carga de **Pedra Solar** (9 cargas, uma por
    sol gravado). A pedra vira pó quando acaba e não recarrega.
  - Força da magia: sol de 50% (amanhecer e entardecer) a 150% (meio-dia),
    lua 60%, Pedra Solar 80%.
- **Batalha por turnos com mira em membros**: cabeça, torso, braços e pernas.
  - Cabeça: difícil de acertar, decepar mata.
  - Braço da arma decepado enfraquece o ataque; sem os dois braços, só chutes.
  - Pernas decepadas: sem esquiva, age por último e não consegue fugir.
  - Membro decepado causa sangramento até usar bandagem ou Sigilo de Vida.
  - Efeitos de corte, impacto, bloqueio, fogo, luz e raio (arte do Carlos).
- **Party** (nomes provisórios): Aren, o prisioneiro (técnicas físicas), e
  Iselde, Marcada (magia). Dano e membros perdidos continuam depois da batalha.
  O altar cura HP/MP, mas o que foi perdido não volta.
- **Inimigos**: Soldado de Sarnheim, Paladino do Décimo Dia (lança raios; no
  escuro usa as próprias Pedras Solares), Cruzado do Décimo Dia e Fiel Oco.

## Estrutura

```
scenes/            cenas (main, mundo, batalha)
scripts/main.gd    troca entre mapa e batalha
scripts/autoload/  Jogo: party, itens, progresso
scripts/mundo/     mapa em grid e dados dos mapas (texto)
scripts/combate/   Combatente (regras dos membros) e a batalha
scripts/data/      inimigos e habilidades
assets/            arte do jogo (32x32 no mapa; 128-256px na batalha)
arte_original/     artes originais do Carlos (o Godot ignora esta pasta)
tools/             processar_artes.py recorta e limpa as artes originais
tests/             teste automático headless
```

## Editando

- **Mapas:** `scripts/mundo/mapas.gd`, desenhados com caracteres (legenda no arquivo).
- **Inimigos:** `scripts/data/inimigos.gd`. As `regioes` são os retângulos de
  cada membro na imagem de batalha; ajuste se trocar a arte.
- **Arte:** coloque a imagem nova em `arte_original/` e rode
  `python3 tools/processar_artes.py` (precisa de Pillow e numpy), ou substitua
  os PNGs em `assets/` mantendo nome e tamanho.
- **Testar uma batalha direto:** `godot -- --batalha paladino`.
- **Testes:** `godot --headless res://tests/teste_auto.tscn`.
- **Exportar local:** instale os templates de exportação do Godot 4.3 e rode
  `godot --headless --export-release "Windows Desktop" build/Aevorath.exe`.
