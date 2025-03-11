# Vite.v <span><img src="https://github.com/siguici/art/blob/HEAD/images/v-vite.svg" alt="⚡" width="24" /></span>

**Vite.v** is a V module that acts as an adapter for integrating
[Vlang](https://vlang.io/) applications with [Vite.js](https://vitejs.dev/).
It simplifies frontend asset handling while ensuring high performance and flexibility.

## 🚀 Features

- 🔌 Tight integration between **V** and **Vite**
- ⚡ Fast builds with optimized asset processing
- 🎯 Simple configuration for effortless usage

## ⚙️ Requirements

Ensure you have the following installed:

- [V](https://vlang.io) (latest version)
- [Vite](https://vitejs.dev) (for frontend compilation)
- [v-vite](https://npm.im/v-vite) (a Vite plugin adapted to V)
  or use the [V Vite Starter template](https://github.com/v-vite/starter)

## 📦 Installation

### Install via VPM (Recommended)

```sh
v install siguici.vite
```

### Install via Git

```sh
mkdir -p ${V_MODULES:-$HOME/.vmodules}/siguici

git clone --depth=1 https://github.com/siguici/vite ${V_MODULES:-$HOME/.vmodules}/siguici/vite
```

### Use Vite.v as a project dependency

```v
Module {
    dependencies: [
        'siguici.vite'
    ]
}
```

## 🔧 Usage

Vite.v is exclusively designed to work with **Veb** ([Veb documentation](https://modules.vlang.io/veb.html)).

### Example

```v
module main

import veb
import siguici.vite { Vite }

pub struct Context {
    veb.Context
}

pub struct App {
pub mut:
    vite Vite
}

fn main() {
    mut app := &App{
        vite: Vite.new()
    }
    veb.run[App, Context](mut app, 8080)
}
```

### Configuration

The configuration is structured as follows:

```v
@[params]
struct ViteConfig {
    manifest_file string = 'manifest.json'
    hot_file      string = 'hot'
    public_dir    string = 'public'
    build_dir     string = 'build'
}
```

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues
and pull requests to improve **Vite.v**.

## 📜 License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.
