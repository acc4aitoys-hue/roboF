from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
import random

app = FastAPI()

# ============================
# Глобальное состояние игры
# ============================

# В реальном проекте так не делают (используют БД),
# но для локальной учебной игры — это идеально.
game_state = {
    "player_hp": 10,
    "bot_hp": 10,
    "message": "Игра началась! Выберите действие.",
    "game_over": False
}


# ============================
# Логика боя
# ============================

def resolve_round(player_action: str):
    """
    Определяет результат раунда.
    Обновляет HP игрока и бота.
    """

    actions = ["attack", "block", "dodge"]
    bot_action = random.choice(actions)

    result_message = f"Вы выбрали {player_action}. Бот выбрал {bot_action}. "

    # Если действия одинаковые — ничья
    if player_action == bot_action:
        result_message += "Ничья!"
        return result_message

    # Логика кто кого побеждает
    wins = {
        "attack": "dodge",   # атака бьёт уворот
        "dodge": "block",    # уворот бьёт блок
        "block": "attack"    # блок бьёт атаку
    }

    # Если игрок победил
    if wins[player_action] == bot_action:
        game_state["bot_hp"] -= 2
        result_message += "Вы выиграли раунд!"
    else:
        game_state["player_hp"] -= 2
        result_message += "Бот выиграл раунд!"

    return result_message


# ============================
# Главная страница
# ============================

@app.get("/", response_class=HTMLResponse)
def read_root():
    """
    Отдаём HTML страницу с кнопками.
    """

    return f"""
    <html>
        <head>
            <title>Robot Duel</title>
            <style>
                body {{
                    font-family: Arial;
                    text-align: center;
                    background-color: #111;
                    color: white;
                }}
                button {{
                    padding: 10px 20px;
                    margin: 10px;
                    font-size: 18px;
                }}
                .hp {{
                    font-size: 20px;
                    margin: 10px;
                }}
            </style>
        </head>
        <body>
            <h1>🤖 Robot Duel Arena</h1>

            <div class="hp">Ваш HP: {game_state["player_hp"]}</div>
            <div class="hp">HP Бота: {game_state["bot_hp"]}</div>

            <p>{game_state["message"]}</p>

            {"<h2>Игра окончена!</h2>" if game_state["game_over"] else ""}

            <form action="/move/attack" method="post">
                <button>🥊 Атака</button>
            </form>

            <form action="/move/block" method="post">
                <button>🛡 Блок</button>
            </form>

            <form action="/move/dodge" method="post">
                <button>🤸 Уклон</button>
            </form>

            <form action="/reset" method="post">
                <button>🔄 Новая игра</button>
            </form>

        </body>
    </html>
    """


# ============================
# Обработка хода игрока
# ============================

#@app.post("/move/{action}")
#def make_move(action: str):
@app.post("/move/{action}", response_class=HTMLResponse)
def make_move(action: str):
    """
    Обрабатывает ход игрока.
    """

    # Если игра уже закончена — не даём ходить
    if game_state["game_over"]:
        return read_root()

    # Вычисляем результат раунда
    message = resolve_round(action)
    game_state["message"] = message

    # Проверяем конец игры
    if game_state["player_hp"] <= 0:
        game_state["message"] += " Вы проиграли!"
        game_state["game_over"] = True

    if game_state["bot_hp"] <= 0:
        game_state["message"] += " Вы победили!"
        game_state["game_over"] = True

    return read_root()


# ============================
# Сброс игры
# ============================

#@app.post("/reset")
#def reset_game():
@app.post("/reset", response_class=HTMLResponse)
def reset_game():
    """
    Сбрасывает состояние игры.
    """

    game_state["player_hp"] = 10
    game_state["bot_hp"] = 10
    game_state["message"] = "Игра началась! Выберите действие."
    game_state["game_over"] = False

    return read_root()
