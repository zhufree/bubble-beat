# 项目规范

本文档旨在为本项目提供一套统一的开发规范和工作流程，确保代码的可读性、可维护性以及团队协作的效率。所有项目成员都应遵循本文档中的规定。

## 1. 项目概述

*   **游戏引擎**: 本项目使用 **Godot Engine 4.5** 版本进行开发。
*   **规范目的**: 统一项目结构、文件命名和代码风格，并规范 AI 辅助开发流程。
-   **AI辅助工具链**: Context7 (API文档) + Godot MCP (项目测试)

---

## 2. 项目结构

项目采用以下目录结构，请将所有文件和资源放置在对应的目录中。

```
.
├── addons/             # Godot 编辑器插件
│
├── assets/             # 存放所有原始媒体资源
│   ├── sprites/        # 静态图片、序列帧等
│   ├── textures/       # 纹理、法线贴图等
│   ├── fonts/          # 字体文件 (.ttf, .otf)
│   └── audio/          # 音效和背景音乐 (.wav, .ogg)
│
├── models/             # 定义数据模型 
├── resources/          # Godot 数据资源 (.tres, .res)，如角色配置、技能数据等
│
├── scenes/             # 包含核心游戏逻辑的场景
│                       # 每个 scenes 由三个同名文件组成：
│                       # - level_one.tscn (场景文件)
│                       # - level_one.gd (仅应用于该场景的脚本)
│                       # - level_one.md (场景说明文档)
│
├── scripts/            # 可在多处复用的通用脚本
│   └── autoload/       # 全局单例脚本 (AutoLoads)
│
├── shaders/            # 着色器文件 (.gdshader)
│
├── views/              # UI/组件场景，不含游戏逻辑，仅负责控件交互
│                       # 完整的 UI 界面，如主菜单、设置界面
│                       # 可复用的 UI 组件，如按钮、血条
│
├── tests/              # 单元测试和集成测试文件
│
├── index.md            # 项目中所有 .md 说明文档的链接索引
└── project.md          # 本文档，定义项目规则
```

---

## 3. 文件命名规范

为保持项目清晰，所有文件和场景的命名需遵循以下规则：

1.  **UI 控件 / 通用脚本 (PascalCase)**
	*   **适用范围**: `views/` 目录下的所有场景和脚本，以及 `scripts/` 目录下的通用脚本。
	*   **规则**: 使用大驼峰命名法 (PascalCase)。
	*   **示例**:
		*   `MainMenu.tscn`
		*   `HealthBar.tscn`
		*   `PlayerController.gd`
		*   `GameStateManager.gd` (在 `scripts/autoload/` 中)

2.  **游戏逻辑场景 (snake_case)**
	*   **适用范围**: `scenes/` 目录下的所有文件。
	*   **规则**: 使用下划线命名法 (snake_case)。场景文件、对应的脚本和说明文档必须使用相同的文件名。
	*   **示例**:
		*   `level_one.tscn`
		*   `level_one.gd`
		*   `level_one.md`

---

## 4. GDScript 代码规范

所有 `.gd` 文件都必须遵循此代码规范。

### 4.1 代码顺序

一个典型的 GDScript 文件应该遵循以下结构顺序：

```gdscript
# 1. 文件级文档字符串（可选）
# "简要描述该脚本的功能"

# 2. class_name (如果需要注册为全局类)
class_name Player

# 3. extends (继承的基类)
extends CharacterBody2D

# 4. 信号 (Signals)
signal health_changed(new_health)
signal died

# 5. 导出变量 (@export)
@export var jump_velocity := -400.0

# 6. 常量 (Constants)
const MAX_HEALTH = 100
const MOVE_SPEED = 250.0

# 7. 枚举 (Enums)
enum State { IDLE, WALK, JUMP }

# 8. OnReady 变量 (@onready)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# 9. 公共变量 (Public Variables)
var current_health := MAX_HEALTH

# 10. 私有变量 (Private Variables,以下划线 `_` 开头)
var _current_state: State = State.IDLE

# 11. 内置虚函数 (Built-in Virtual Functions)
# e.g., _init, _ready, _process, _physics_process, _input, etc.
func _ready():
	current_health = MAX_HEALTH

func _physics_process(delta):
	pass

# 12. 公共方法 (Public Methods)
func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health)
	if current_health <= 0:
		died.emit()

# 13. 私有方法 (Private Methods, 以下划线 `_` 开头)
func _update_animation():
	pass

# 14. 信号回调方法 (Signal Callbacks)
# 命名约定: _on_[NodeName]_[signal_name]
func _on_hitbox_area_entered(area):
	pass
```

### 4.2 命名约束

*   **常量 (Constants)**: 使用大写字母和下划线 `UPPER_SNAKE_CASE`。
*   **变量 (Variables)**: 使用小写字母和下划线 `snake_case`。私有变量以 `_` 开头。
*   **函数/方法 (Functions/Methods)**: 使用小写字母和下划线 `snake_case`。私有方法以 `_` 开头。
*   **信号 (Signals)**: 使用小写字母和下划线 `snake_case`，通常以过去式命名。
*   **类 (Classes / `class_name`)**: 使用大驼峰 `PascalCase`。

---

## 5. 文档规范

清晰的文档是项目长期维护的关键。

*   **复杂逻辑说明**: 如果当前实现的内容、算法或系统逻辑比较复杂（例如：状态机、复杂的 UI 交互、程序化生成算法等），必须创建对应的 Markdown (`.md`) 文件进行说明。
*   **文件位置**: 该说明文档应与对应的场景/脚本放在同一目录下，并使用相同的 **snake_case** 命名。
	*   例如，`scenes/` 目录下的 `inventory_system.tscn` 和 `inventory_system.gd`，其说明文档为 `inventory_system.md`。
*   **索引更新**: 创建新的说明文档后，**必须**在项目根目录的 `index.md` 文件中添加指向该文档的链接和简要描述，以维护一个集中的文档索引。

---

## 6. AI 行为与代码规范指导说明

本节内容为项目开发中与 AI 交互时的核心指导原则，旨在确保 AI 的输出高质量、符合架构目标。

### AI 核心定位

你是一名经验丰富的**软件开发工程师**，专注于构建**可维护、健壮**的解决方案。

你的任务是：**审查、理解并迭代式地改进/推进一个游戏项目。**

在整个工作流程中，你必须内化并严格遵循以下核心编程原则，确保你的每次输出和建议都体现这些理念：

*   **简单至上 (KISS):** 追求代码和设计的极致简洁与直观，避免不必要的复杂性。
*   **精益求精 (YAGNI):** 仅实现当前明确所需的功能，抵制过度设计和不必要的未来特性预留。
*   **坚实基础 (SOLID):**
	*   **S (单一职责):** 各组件、类、函数只承担一项明确职责。
	*   **O (开放/封闭):** 功能扩展无需修改现有代码。
	*   **L (里氏替换):** 子类型可无缝替换其基类型。
	*   **I (接口隔离):** 接口应专一，避免“胖接口”。
	*   **D (依赖倒置):** 依赖抽象而非具体实现。
*   **杜绝重复 (DRY):** 识别并消除代码或逻辑中的重复模式，提升复用性。

### AI 工作流程与输出要求

请严格遵循以下工作流程和输出要求：

1.  **任务定义与分解：**
	* 详细审阅提供的资料/代码/项目描述，全面掌握其当前架构、核心组件、业务逻辑及痛点。
	* 在理解的基础上，初步识别项目中潜在的**KISS, YAGNI, DRY, SOLID**原则应用点或违背现象。
	* 清晰定义本次迭代的具体任务范围和可衡量的预期成果。
	* 如果任务复杂，将其分解为更小的、可管理的部分。

2.  **查询最新文档**
	- 使用 **Context7** (AI文档查询工具) 获取最新的API参考和类文档
	- 重点检查 Godot 4.5 新特性：确认使用 Callable 替代旧版 `connect()` 语法
	- 确保生成的代码使用最新的最佳实践和API
	* **指令示例**: "Always use `context7` when I need code generation. Use library `godotengine_en_stable` for API and docs."

3.  **代码生成**
	- 向 AI 提交包含清晰指令和项目相关上下文（如现有代码）的请求。
	- 结合从 `context7` 获取的最新信息，指导 AI 生成符合项目规范、逻辑正确且版本兼容的代码。
	* 这些代码需要满足**KISS, YAGNI, DRY, SOLID**原则。例如：
		* “将此模块拆分为更小的服务，以遵循SRP和OCP。”
		* “为避免DRY，将重复的XXX逻辑抽象为通用函数。”
		* “简化了Y功能的用户流，体现KISS原则。”
		* “移除了Z冗余设计，遵循YAGNI原则。”

4.   **项目调试**
	*   **集成**: 将 AI 生成或修改的代码集成到项目中。
	*   **运行**: 在终端中，使用 `godot-mcp` 启动项目进行测试。 `godot-mcp run_project`
	*   **调试**: 运行后，主动获取控制台输出以检查错误或警告。 `godot-mcp get_debug_output`
	*   **修正**: 根据控制台输出的错误信息，结合 AI 或自行分析定位并修正问题。这是一个循环过程：**运行 -> 获取输出 -> 修正代码 -> 重新运行**。
	*   **停止**: 功能验证通过后，停止项目运行。`godot-mcp stop_project`

5.  **总结、反思与展望（汇报阶段）：**
	*   提供一个清晰、结构化且包含**实际代码/设计变动建议（如果适用）**的总结报告。
	*   报告中必须包含：
		*   **本次迭代已完成的核心任务**及其具体成果。
		*   **本次迭代中，你如何具体应用了** **KISS, YAGNI, DRY, SOLID** **原则**，并简要说明其带来的好处（例如，代码量减少、可读性提高、扩展性增强）。
		*   **遇到的挑战**以及如何克服。
		*   **下一步的明确计划和建议。**

---

## 7. 版本控制要求

### 7.1 提交信息规范

遵循 Conventional Commits 规范，使用以下格式：

```bash
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Type 类型：**
- `feat`: 新功能
- `fix`: 修复 Bug
- `docs`: 文档更新
- `style`: 代码格式修改（不影响功能）
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建流程、辅助工具等

**示例：**
```bash
feat(player): 添加跳跃能力和双跳机制
fix(ai): 修正敌人寻路路径计算错误
docs(readme): 更新安装说明
refactor(inventory): 重构物品管理系统以提高性能
chore(ui): 优化血条显示性能
```
