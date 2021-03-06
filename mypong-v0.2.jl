# Deklaracja używanego pakietu
using SFML
using BackpropNeuralNet

# Zmienne zdefiniowane globalnie - takie pseudostałe parametry
ball_radius = 10.0;
ball_maxvelocity = 6.0;

paddle_width = 15.0;
paddle_height = 150.0;
paddle_velocity = 6.0;

window_width = 800;
window_height = 600;

screen = SFML.Image{};

# Zdefiniowanie typów potrzebnych do obsługi elementów
type Score
    p1::Int
    p2::Int
end

type Ball
    shape::CircleShape
    velocity::Vector2f
    starting_pos::Vector2f
end

type Paddle
    shape::RectangleShape
    velocity::Vector2f
    up_direction::Int
    down_direction::Int
end

# Funkcje obsługujące tworzenie obiektów
function Ball(x, y)
    # obiekt piłki
    ball = Ball(CircleShape(), Vector2f(ball_maxvelocity, ball_maxvelocity/2), Vector2f(x, y));
    # pozycja
    set_position(ball.shape, ball.starting_pos);
    # promień
    set_radius(ball.shape, ball_radius);
    # kolor piłki
    set_fillcolor(ball.shape, SFML.white);
    # punkt centralny
    set_origin(ball.shape, Vector2f(ball_radius, ball_radius));

    return ball;
end

function Paddle(x, y, up_direction, down_direction)
    # obiekt paletki
    paddle = Paddle(RectangleShape(), Vector2f(0.0, 0.0), up_direction, down_direction);
    # pozycja
    set_position(paddle.shape, Vector2f(x,y));
    # rozmiar
    set_size(paddle.shape, Vector2f(paddle_width, paddle_height));
    # kolor
    set_fillcolor(paddle.shape, SFML.white);
    # punkt centralny
    set_origin(paddle.shape, Vector2f(paddle_width/2, paddle_height/2));
    
    return paddle;
end

# Funkcje sterujące
function resetBall(ball::Ball, direction::Int)
    # ustawienie piłki w pozycję startową
    set_position(ball.shape, ball.starting_pos);
    # zmiana kierunku lotu piłki
    ball.velocity = Vector2f(direction*ball_maxvelocity, ball_maxvelocity/2);
end

function updateState(ball::Ball, p1::Paddle, p2::Paddle, score::Score)
    # przesunięcie piłki o wektor prędkości
    move(ball.shape, ball.velocity);
    
    # zebranie wartości pozycji piłki
    ball_position = get_position(ball.shape);
    ball_x = ball_position.x; ball_y = ball_position.y;
    
    # zebranie wartości promienia
    ball_radius = get_radius(ball.shape);
    
    # pozycja paletek
    p1_position = get_position(p1.shape);
    p2_position = get_position(p2.shape);
    
    # warunki brzegowe piłki przy odbiciach
    if ball_y - ball_radius <= 0  
        ball.velocity.y = ball_maxvelocity;
    elseif ball_y + ball_radius >= window_height 
        ball.velocity.y = -ball_maxvelocity;
    end
    
    if ball_x - ball_radius <= 0
        # strzał lewa paletka
        score.p2 += 1;
        resetBall(ball, 1);
    elseif ball_x + ball_radius >= window_width
        # strzał prawa paletka
        score.p1 += 1;
        resetBall(ball, -1);
    elseif ball_y == p1_position.y - paddle_height/2 && ball_x - ball_radius == p1_position.x + paddle_width/2 && ball.velocity.y > 0
        # piłka w dół | lewa paletka | krawędź górna
        ball.velocity.x *= -1;
        ball.velocity.y *= -1;
    elseif ball_y == p1_position.y + paddle_height/2 && ball_x - ball_radius == p1_position.x + paddle_width/2 && ball.velocity.y < 0
        # piłka w górę | lewa paletka | krawędź dolna
        ball.velocity.x *= -1;
        ball.velocity.y *= -1;
    elseif ball_y >= p1_position.y - paddle_height/2 && ball_y <= p1_position.y + paddle_height/2 && ball_x - ball_radius <= p1_position.x + paddle_width/2
        # lewa paletka
        ball.velocity.x *= -1;
    elseif ball_y >= p2_position.y - paddle_height/2 && ball_y <= p2_position.y + paddle_height/2 && ball_x + ball_radius >= p2_position.x - paddle_width/2
        # prawa paletka
        ball.velocity.x *= -1;
    elseif ball_y == p2_position.y - paddle_height/2 && ball_x + ball_radius == p2_position.x - paddle_width/2 && ball.velocity.y > 0;
        # piłka w dół | prawa paletka | krawędź górna
        ball.velocity.x *= -1;
        ball.velocity.y *= -1;
    elseif ball_y == p2_position.y + paddle_height/2 && ball_x + ball_radius == p2_position.x - paddle_width/2 && ball.velocity.y < 0;
        # piłka w górę | prawa paletka | krawędź dolna
        ball.velocity.x *= -1;
        ball.velocity.y *= -1;
    end
    
    if ball_x < window_width/2
        checkpaddle = p1;
    else
        checkpaddle = p2;
    end
    
    if ball.velocity.y > 0
        if checkpaddle.velocity.y > 0
            ball.velocity.y *= 1.05;
        elseif checkpaddle.velocity.y < 0;
            ball.velocity.y *= 0.95;
        end
    elseif ball.velocity.y < 0
        if checkpaddle.velocity.y < 0
            ball.velocity.y *= 1.05;
        elseif checkpaddle.velocity.y > 0;
            ball.velocity.y *= 0.95;
        end
    end
end

function updatePaddle(paddle::Paddle)
    # przesuń paletkę
    move(paddle.shape, paddle.velocity)
    # pozycja paletki
    position = get_position(paddle.shape)
    x = position.x; y = position.y
    # sprawdzaj klawisze
    if (is_key_pressed(paddle.up_direction))
        if y - paddle_height/2 <= 0
            paddle.velocity.y = 0;
        else
            paddle.velocity.y = -paddle_velocity
        end
    elseif (is_key_pressed(paddle.down_direction))
        if y + paddle_height/2 >= window_height
            paddle.velocity.y = 0;
        else
            paddle.velocity.y = paddle_velocity
        end
    else
        paddle.velocity.y = 0
    end
end

function main()
    # Ustawienie wyniku
    score = Score(0, 0)
    # Stworzenie obiektu tekstu
    score_text = RenderText()
    # wartość tekstu
    set_string(score_text, "$(score.p1)     $(score.p2)")
    # kolor tekstu
    set_color(score_text, Color(255, 255, 255))
    # pozycja tekstu
    set_position(score_text, Vector2f(window_width/2 - 100, 60))
    # rozmiar tekstu
    set_charactersize(score_text, 50)
    
    # utworzenie piłki
    ball = Ball(window_width / 2, window_height / 2)
    
    # utworzenie paletek
    paddle1 = Paddle(50, window_height / 2, KeyCode.W, KeyCode.S)
    paddle2 = Paddle(window_width - 50, window_height / 2, KeyCode.UP, KeyCode.DOWN)

    paddles = Paddle[]
    push!(paddles, paddle1)
    push!(paddles, paddle2)

    # utworzenie okna
    window = RenderWindow("Pong", window_width, window_height)
    set_framerate_limit(window, 60)
    set_vsync_enabled(window, true)

    event = Event()
    
    #@async # sieć_neuronowa
    @async while isopen(window)
        #nasłuchiwanie eventów
        while pollevent(window, event)
            if get_type(event) == EventType.CLOSED
                close(window)
            elseif get_type(event) == EventType.KEY_PRESSED
               updatePaddle( paddle1 );
            end
        end

        set_string(score_text, "$(score.p1)      $(score.p2)")

        clear(window, SFML.black)

        #if collides(ball, paddle1) || collides(ball, paddle2)
        #   ball.velocity.x = -ball.velocity.x
        #end

        updateState(ball, paddles[1], paddles[2], score)
        draw(window, ball.shape)
        for i in 1:length(paddles)
            updatePaddle(paddles[i])
            draw(window, paddles[i].shape)
        end

        draw(window, score_text)
        display(window)
        
        # screen = capture(window);
    end
end

@sync main()