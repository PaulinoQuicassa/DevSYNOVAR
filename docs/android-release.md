# Publicar a app Android na Google Play

Este documento cobre o que falta desde o código já preparado (ver
commit `audit-fixes-...`, 2026-09-10) até uma publicação real na Play
Store. As secções 1-3 já estão feitas neste repo; as secções 4+ são
passos que só o dono da conta Google Play consegue dar.

## 1. `applicationId` (feito)

`com.filacerta.app` — definido em `android/app/build.gradle.kts` e no
pacote de `MainActivity.kt`. **Não pode ser mudado depois do primeiro
upload à Play Store** (a Google usa-o para identificar a app para
sempre). Se quiser outro antes da primeira publicação, é só mudar nos
dois sítios.

## 2. Assinatura de release (feito, chave gerada nesta máquina)

Foi gerada uma keystore de produção real:

- Ficheiro: `C:\Users\Paulino Quicassa\Desktop\Fila Certa - chaves\filacerta-release.jks`
- Ver `LEIA-ME.txt` nessa mesma pasta para a palavra-passe e alias.
- `android/key.properties` (nesta máquina, **não commitado** — está no
  `.gitignore`) já aponta para ela. `android/key.properties.example`
  mostra o formato caso seja preciso recriar noutra máquina.

**Faça já uma cópia de segurança da keystore fora deste computador**
(gestor de palavras-passe, cloud cifrada, pen dedicada). Perder este
ficheiro ou a palavra-passe significa nunca mais poder publicar uma
actualização a esta app — só resta lançar uma app nova, do zero.

Sem este ficheiro (ex.: no CI), o build de release cai automaticamente
para a chave de debug — suficiente para confirmar que a app compila,
nunca para publicar.

Para gerar uma AAB assinada de verdade nesta máquina:

```
flutter build appbundle --release
# saída: build/app/outputs/bundle/release/app-release.aab
```

## 3. Ícone (feito, provisório)

Os `mipmap-*/ic_launcher.png` (e os ícones web equivalentes) deixaram
de ser o logótipo por omissão do Flutter — agora é um desenho simples
("ficha de fila") nas cores reais da app (`lib/theme/app_theme.dart`).
**Isto é um placeholder, não branding final** — vale a pena substituir
por um ícone desenhado de propósito antes do lançamento público. Para
regenerar a partir de uma imagem nova, os tamanhos Android são:
`mipmap-mdpi` 48×48, `hdpi` 72×72, `xhdpi` 96×96, `xxhdpi` 144×144,
`xxxhdpi` 192×192 (todos `ic_launcher.png`).

## 4. Antes de gerar a AAB final -- rever

- **`versionName`/`versionCode`** em `pubspec.yaml` (`version: 1.0.0+1`)
  -- subir a cada envio à Play Store (o `versionCode`, o `+1`, tem de
  ser sempre maior que o anterior).
- **`minSdk`/`targetSdk`**: geridos pela versão do Flutter instalada
  (`flutter.minSdkVersion`/`flutter.targetSdkVersion`). A Google exige
  todos os anos um `targetSdk` mínimo mais recente -- confirmar que a
  versão do Flutter usada no build ainda cumpre o requisito da altura
  do envio.
- Nunca correu num dispositivo/emulador Android real (só Web até
  agora) -- testar o fluxo todo (tirar senha, geolocalização,
  notificação sonora, abrir WhatsApp) num Android antes de submeter.

## 5. Passos que só o dono da conta consegue dar

1. Criar conta em [Google Play Console](https://play.google.com/console)
   (pagamento único de 25 USD).
2. Publicar uma **política de privacidade** num URL público -- a app
   pede localização e cria conta de utilizador, a Play Store exige uma
   política acessível antes de aprovar a ficha.
3. Preencher o questionário **"Segurança dos dados"** na Play Console
   (que dados são recolhidos: localização, identificadores de conta;
   com quem são partilhados: Supabase, Sentry).
4. Ficha da loja: descrição curta/longa, ícone 512×512 (final, não o
   placeholder), pelo menos 2 capturas de ecrã reais em telemóvel
   Android.
5. Enviar a AAB assinada (secção 2) numa faixa de **teste interno**
   primeiro, testar num telemóvel real, só depois promover a produção.
6. A primeira revisão da Google pode demorar alguns dias, e pode pedir
   justificação extra por causa da permissão de localização (declarar
   no questionário que é usada só para "localizações próximas",
   nunca partilhada com terceiros para publicidade).

## 6. Notificações push (fora de âmbito desta ronda)

Hoje o aviso "é a sua vez"/"está quase" só chega com a app aberta. Numa
app de telemóvel a expectativa é receber isto com a app fechada -- isso
precisa de um serviço de push (Firebase Cloud Messaging ou equivalente)
e não foi implementado nesta ronda. Sem isto, a app funciona, mas perde
a vantagem principal de ser uma app própria em vez de continuar a usar
o site.
