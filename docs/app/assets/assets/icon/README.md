# Como Gerar o Ícone do App

## Opção 1: Converter SVG Online (Mais Fácil)

1. Abra o arquivo `icon_source.svg` em um navegador
2. Use um site como:
   - https://cloudconvert.com/svg-to-png
   - https://svgtopng.com/
3. Converta para PNG com 1024x1024 pixels
4. Salve como `app_icon.png` nesta pasta
5. Crie uma versão só com o centro (sem fundo) como `app_icon_foreground.png`

## Opção 2: Capturar do App

1. Execute o app: `flutter run`
2. Vá em Configurações → "Ver ícone em detalhes"
3. Tire um screenshot do ícone grande
4. Corte para 1024x1024 pixels
5. Salve como `app_icon.png`

## Opção 3: Usar Figma/Illustrator

1. Importe o `icon_source.svg`
2. Exporte como PNG 1024x1024

## Depois de Criar o PNG

Execute o comando para gerar os ícones:

```bash
flutter pub get
dart run flutter_launcher_icons
```

Isso vai gerar automaticamente todos os tamanhos necessários para Android e iOS.

## Cores Usadas

| Elemento | Cor | Hex |
|----------|-----|-----|
| Fundo | Azul Escuro | #1A237E |
| Radar/Linhas | Laranja Bitcoin | #F7931A |
| Centro | Gradiente Laranja | #FF9800 → #FF5722 |
| Bitcoin | Laranja | #F7931A |
| Ethereum | Roxo | #627EEA |
| XRP | Azul | #00AAE4 |
| Sinal/Seta | Verde | #4CAF50 |

