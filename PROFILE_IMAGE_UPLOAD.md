# Profile Image U  - Redimensionamento automático (1000x1000 max)load System

## Visão Geral

O sistema de upload de imagem de perfil foi implementado com as seguintes funcionalidades:

### Arquivos Criados

1. **`profile_pic_select.dart`** - Gerenciamento de seleção e upload de imagens
2. **`profile_credit_info.dart`** - Componente de informações de créditos (separado)
3. **`profile_pic.dart`** - Componente de exibição da imagem (atualizado)

## Funcionalidades Implementadas

### 📱 **Seleção de Imagem**
- Seleção via **Galeria** ou **Câmera**
- Dialog modal intuitivo para escolha da fonte
- Redimensionamento automático (512x512 max)
- Compressão de qualidade (85%)

### 🌐 **Upload Automático**
- Conversão para Base64
- Envio via API REST com autenticação Firebase
- Loading dialog durante upload
- Feedback visual de sucesso/erro

### 💾 **Persistência**
- Salva URL da imagem no Firestore
- Integração automática com perfil do usuário
- Suporte para URLs web e assets locais

## Como Usar

### 1. **Seleção Simples**
```dart
final imageFile = await ProfilePicSelect.selectImage(
  source: ImageSource.gallery, // ou ImageSource.camera
  maxWidth: 1000,
  maxHeight: 1000,
  imageQuality: 85,
);
```

### 2. **Dialog de Seleção**
```dart
final imageFile = await ProfilePicSelect.showImageSourceDialog(context);
```

### 3. **Upload com Loading**
```dart
final result = await ProfilePicSelect.uploadWithLoading(
  context: context,
  imageFile: imageFile,
);
```

### 4. **Processo Completo (Recomendado)**
```dart
final result = await ProfilePicSelect.selectAndUploadImage(context);
if (result != null && result.success) {
  print('Imagem enviada: ${result.imageUrl}');
}
```

## Estrutura da API

### Endpoint 
```
POST /profile_image
```

### Headers
```
Authorization: Bearer <firebase_token>
```

### Body da Requisição (Multipart Form-Data)
```
Content-Disposition: form-data; name="file"; filename="profile_<user_id>.jpg"
Content-Type: image/jpeg

<binary_image_data>
```
  "user_id": "<firebase_user_id>"
}
```

### Resposta de Sucesso
```json
{
  "success": true,
  "message": "Imagem enviada com sucesso"
}
```

### Resposta de Erro
```json
{
  "success": false,
  "message": "Mensagem de erro detalhada"
}
```

## Integração com Firestore

### Estrutura do Documento do Usuário
```json
{
  "display_name": "João Silva",
  "email": "joao@exemplo.com",
  "profile_image_url": "https://exemplo.com/images/profile_123.jpg",
  "language": "pt",
  "currency": "BRL",
  "country": "Brasil"
}
```

## Componentes Visuais

### ProfilePic
- Exibe imagem circular com borda de progresso
- Suporte para URLs web e assets locais
- Loading automático para imagens da internet
- Avatar padrão com gradiente quando sem imagem
- Ícone de edição quando `isEditable: true`

### ProfileCreditInfo
- Card com informações de créditos
- Cálculo automático de percentuais
- Barra de progresso linear
- Cores dinâmicas baseadas no usage

## Dependências Adicionadas

```yaml
dependencies:
  image_picker: ^1.0.4  # Para seleção de imagens
```

## Fluxo Completo

1. **Usuário toca no ícone de edição** → Abre dialog de seleção
2. **Escolhe Galeria ou Câmera** → Abre seletor nativo
3. **Seleciona imagem** → Imagem é redimensionada e comprimida
4. **Upload automático** → Converte para Base64 e envia para API
5. **API processa** → Salva imagem e retorna URL
6. **Atualiza interface** → Exibe nova imagem e habilita botão "Salvar"
7. **Usuário salva perfil** → URL é persistida no Firestore

## Exemplo de Uso Completo

```dart
ProfilePic(
  size: 120,
  totalCredits: 1000,
  usedCredits: 25,
  imagePath: _profileImageUrl, // URL da imagem atual
  isEditable: _isEditing,
  onTap: _isEditing ? () async {
    final result = await ProfilePicSelect.selectAndUploadImage(context);
    if (result != null && result.success) {
      setState(() {
        _profileImageUrl = result.imageUrl;
        _hasChanged = true;
      });
    }
  } : null,
),
```

## Notas Técnicas

- **Formatos suportados**: JPG, PNG, WebP
- **Tamanho máximo recomendado**: 2MB
- **Resolução máxima**: 1000x1000 pixels
- **Compressão**: 85% de qualidade
- **Autenticação**: Firebase ID Token
- **Timeout**: 30 segundos para upload
