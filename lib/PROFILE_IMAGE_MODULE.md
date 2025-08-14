# Profile Image Module - Documentação

## Estrutura Modular

A funcionalidade de imagem de perfil foi modularizada para melhor organização, manutenção e testabilidade:

### 📁 Arquitetura

```
lib/
├── services/
│   ├── profile_image_service.dart      # API e comunicação com servidor
│   ├── image_picker_service.dart       # Seleção de imagens
│   └── profile_image_uploader.dart     # Upload com UI
├── widgets/
│   └── image_source_dialog.dart        # Modal de seleção
├── profile_pic_select.dart             # Classe principal (facade)
└── profile_image_module.dart           # Exportações
```

---

### 🔧 Componentes

#### **1. ProfileImageService** (`services/profile_image_service.dart`)
- **Responsabilidade**: Comunicação com API
- **Funcionalidades**:
  - `getProfileImageUrl()` - Busca URL da imagem no servidor
  - `uploadProfileImage()` - Upload multipart para API
  - Gerenciamento de autenticação Firebase
  - Tratamento de erros de rede

#### **2. ImagePickerService** (`services/image_picker_service.dart`)
- **Responsabilidade**: Seleção e validação de imagens
- **Funcionalidades**:
  - `selectImage()` - Seleciona da galeria ou câmera
  - Configurações de qualidade e tamanho
  - Validação de arquivo (tamanho máximo 5MB)
  - Classe `ImagePickerConfig` para configurações

#### **3. ProfileImageUploader** (`services/profile_image_uploader.dart`)
- **Responsabilidade**: Upload com interface de usuário
- **Funcionalidades**:
  - `uploadWithLoading()` - Upload com dialog de loading
  - `uploadSilent()` - Upload sem UI
  - Gerenciamento de mensagens de sucesso/erro
  - SnackBar automático para feedback

#### **4. ImageSourceDialog** (`widgets/image_source_dialog.dart`)
- **Responsabilidade**: Modal de seleção de origem
- **Funcionalidades**:
  - Interface para escolher galeria/câmera
  - Design moderno com bottom sheet
  - Método estático `show()` para fácil uso

#### **5. ProfilePicSelect** (`profile_pic_select.dart`)
- **Responsabilidade**: Facade/Coordenador principal
- **Funcionalidades**:
  - API pública unificada
  - Coordena todos os serviços
  - Mantém compatibilidade com código existente
  - Métodos de conveniência

---

### 🚀 Como Usar

#### **Importação Simples**
```dart
// Uma única importação para tudo
import 'profile_image_module.dart';

// Ou importação específica
import 'profile_pic_select.dart';
```

#### **Uso Básico**
```dart
// Seleção e upload completo (recomendado)
final result = await ProfilePicSelect.selectAndUploadImage(context);

// Seleção e upload silencioso
final result = await ProfilePicSelect.selectAndUploadSilent(context);

// Obter URL da imagem existente
final url = await ProfilePicSelect.getProfileImageUrl();
```

#### **Uso Avançado com Configurações**
```dart
// Configuração personalizada
const config = ImagePickerConfig(
  maxWidth: 800,
  maxHeight: 800,
  imageQuality: 90,
);

// Upload com configurações customizadas
final result = await ProfilePicSelect.selectAndUploadImage(
  context,
  config: config,
  loadingMessage: 'Processando foto...',
);
```

#### **Uso Modular Direto**
```dart
// Usar serviços individuais se necessário
final imageFile = await ImagePickerService.selectImage(
  source: ImageSource.camera,
  config: const ImagePickerConfig(imageQuality: 100),
);

if (imageFile != null) {
  final result = await ProfileImageUploader.uploadWithLoading(
    context: context,
    imageFile: imageFile,
  );
}
```

---

### ✅ Vantagens da Modularização

1. **Separação de Responsabilidades**: Cada módulo tem uma função específica
2. **Testabilidade**: Serviços podem ser testados individualmente
3. **Reutilização**: Componentes podem ser usados em outros contextos
4. **Manutenibilidade**: Mudanças são isoladas em módulos específicos
5. **Flexibilidade**: Diferentes fluxos de uso (com/sem UI)
6. **Compatibilidade**: API existente mantida no `ProfilePicSelect`

---

### 🔄 Migração

**Código existente continua funcionando sem mudanças:**
```dart
// ✅ Continua funcionando
final result = await ProfilePicSelect.selectAndUploadImage(context);
final url = await ProfilePicSelect.getProfileImageUrl();
```

**Novas funcionalidades disponíveis:**
```dart
// ✅ Novas opções
final result = await ProfilePicSelect.selectAndUploadSilent(context);
final result = await ProfilePicSelect.uploadWithLoading(
  context: context,
  imageFile: file,
  loadingMessage: 'Enviando...',
);
```

---

### 🧪 Testes

Cada módulo pode ser testado independentemente:

- **ProfileImageService**: Mock das chamadas HTTP
- **ImagePickerService**: Mock do ImagePicker
- **ProfileImageUploader**: Mock dos dialogs
- **ImageSourceDialog**: Testes de widget
- **ProfilePicSelect**: Testes de integração

---

### 📈 Extensibilidade

A estrutura modular permite fácil extensão:

- **Novos provedores de imagem** (ex: redes sociais)
- **Diferentes tipos de validação**
- **Temas personalizados para dialogs**
- **Diferentes estratégias de upload**
- **Cache de imagens**
- **Compressão avançada**
