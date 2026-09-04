# Troubleshooting

Esta página registra os problemas encontrados no laboratório, os testes utilizados e a causa identificada.

## 1. RDP indisponível após a criação da VM

### Sintoma

O cliente RDP não conseguia estabelecer conexão com a `vm-app`.

### Investigação

O NSG havia sido associado à subnet `sub-app`, e não diretamente à placa de rede. Portanto, as regras efetivas da VM dependiam do NSG aplicado à subnet.

### Correção

Foi criada uma regra inbound temporária permitindo TCP 3389 para a origem administrativa utilizada no laboratório.

### Aprendizado

Uma VM pode ser afetada por NSGs associados à subnet e/ou à interface de rede. É necessário verificar as regras efetivas, não apenas a NIC.

---

## 2. Rede corporativa bloqueando RDP

### Sintoma

Mesmo com a regra do Azure configurada, o acesso RDP falhava a partir da rede do trabalho.

### Teste

```powershell
Test-NetConnection <IP-PUBLICO-DA-VM> -Port 3389
```

A conexão falhou na rede corporativa e funcionou por uma conexão pessoal, isolando o bloqueio fora do Azure.

### Aprendizado

Um NSG liberado não garante conectividade de ponta a ponta. Firewalls e proxies da rede de origem também podem impedir a conexão.

---

## 3. Certificado não confiável no SSMS

### Sintoma

O SSMS estabelecia comunicação com o SQL Server, mas interrompia o login porque a cadeia do certificado não era confiável.

### Correção no laboratório

Foi habilitada a opção **Trust Server Certificate** no cliente.

### Aprendizado

A conectividade e a autenticação podem estar corretas mesmo quando a negociação TLS falha. Em produção, a solução adequada é utilizar um certificado emitido por uma autoridade confiável.

---

## 4. Validação da porta do SQL Server

A partir da `vm-app`, foi executado:

```powershell
Test-NetConnection vm-db -Port 1433
```

O resultado resolveu `vm-db` para um IP privado da `sub-db` e retornou:

```text
TcpTestSucceeded : True
```

Isso validou em um único teste:

- resolução de nome;
- roteamento interno da VNet;
- regras de segurança;
- firewall do sistema operacional;
- serviço escutando na porta esperada.

---

## 5. HTTP 502.5 — ANCM Out-of-Process Startup Failure

### Sintoma

O IIS retornava:

```text
HTTP Error 502.5 - ANCM Out-of-Process Startup Failure
```

### Investigação

O Event Viewer mostrou que a aplicação `Badges.dll` tinha como dependência:

```text
Microsoft.NETCore.App 6.0.0 (x64)
```

A VM possuía somente o runtime .NET 7. A versão 7 não atendia automaticamente a uma aplicação compilada para .NET 6.

### Correção

Foi instalado o **.NET 6 Hosting Bundle**, que adicionou o runtime exigido e a integração do ASP.NET Core com IIS. Em seguida:

```powershell
iisreset
dotnet --list-runtimes
```

Após a instalação, a aplicação iniciou corretamente.

### Aprendizado

Erros HTTP genéricos devem ser investigados nos logs da aplicação e do servidor. Instalar uma versão mais nova do runtime não garante compatibilidade com uma aplicação direcionada a outra versão principal.

---

## 6. Acesso externo forçado para HTTPS

### Sintoma

A aplicação funcionava em `localhost`, mas o acesso pelo IP público expirava no navegador.

### Investigação

O IIS estava escutando corretamente:

```powershell
Test-NetConnection localhost -Port 80
Get-WebBinding
```

O navegador acrescentava HTTPS automaticamente, enquanto o laboratório possuía apenas binding HTTP na porta 80.

### Correção

O endereço foi informado explicitamente com o esquema:

```text
http://<IP-PUBLICO-DA-VM>
```

### Aprendizado

HTTP 80 e HTTPS 443 são serviços diferentes. Liberar a porta 80 não configura certificado nem binding HTTPS.
