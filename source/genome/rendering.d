module genome.rendering;

import genome.simobject;
import genome.map;
import genome.settings.config;
import genome.input;

Renderer renderer;

public template colorFromHEX(int hex)
{
    public enum Color colorFromHEX = Color(
        cast(ubyte)((hex >> 16) & 0xFF), // Red
        cast(ubyte)((hex >> 8) & 0xFF),  // Green
        cast(ubyte)(hex & 0xFF),         // Blue
        255                               // Alpha
    );
}

struct Color
{
    public:
    ubyte r, g, b, a;

    this(ubyte r, ubyte g, ubyte b, ubyte a = 255)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }
}

struct Renderable
{
    Color color;
}


struct Renderer
{
    import raylib;

    private Camera2D Camera;
    private Image SimScreen;
    private Texture2D SimScreenTexture;

    /// Create window
    /// Params:
    ///   title = window title
    public void createWindow(string title)
    {
        immutable int width = GetScreenWidth();
        immutable int height = GetScreenHeight();

        if(grc.renderMode == RenderMode.fullscreen)
        {
            SetConfigFlags(ConfigFlags.FLAG_FULLSCREEN_MODE);
        }
        else if(grc.renderMode == RenderMode.borderless)
        {
            SetConfigFlags(ConfigFlags.FLAG_WINDOW_UNDECORATED );
        }
        else
        {
            throw new Exception("Unknown render mode!");
        }
        InitWindow(width, height, title.ptr);

        SimScreen = GenImageColor(gsic.xMapSize, gsic.yMapSize, Colors.BLACK);
        SimScreenTexture = LoadTextureFromImage(SimScreen);

        Camera.target = Vector2(0, 0);
        Camera.offset = Vector2(width / 2, height / 2);
        Camera.rotation = 0;
        Camera.zoom = 1.0f;
    }

    public void setColor(int[2] position, Color color)
    {
        ImageDrawPixel(&SimScreen, position[0], position[1], cast(raylib.Color) color);
    }

    public void update()
    {
        enum float zoomMultiplier = 0.1;
        enum float minimalZoom = 0.1;
        
        float wheel = GetMouseWheelMove();
        if (wheel != 0)
        {
            Vector2 mouseWorldPos = GetScreenToWorld2D(GetMousePosition(), Camera);
            Camera.offset = GetMousePosition();
            Camera.target = mouseWorldPos;
            
            Camera.zoom += wheel * zoomMultiplier;

            if (Camera.zoom < minimalZoom) Camera.zoom = minimalZoom;
        }

        immutable float moveSpeed = 100.0f * GetFrameTime() / Camera.zoom;
        if (Input.IsKeyDown(Keys.w)) Camera.target.y -= moveSpeed;
        if (Input.IsKeyDown(Keys.s)) Camera.target.y += moveSpeed;
        if (Input.IsKeyDown(Keys.a)) Camera.target.x -= moveSpeed;
        if (Input.IsKeyDown(Keys.d)) Camera.target.x += moveSpeed;

        BeginDrawing();
        ClearBackground(Colors.BLACK);
        BeginMode2D(Camera);

        UpdateTexture(SimScreenTexture, SimScreen.data);
        DrawTexture(SimScreenTexture, 0, 0, Colors.RAYWHITE);     

        EndMode2D();
        EndDrawing();     
    }
    public bool shouldEndDrawing() => WindowShouldClose();
}

@AddAtStart
class RenderableSystem : System!Renderable
{
    mixin CreateMethod!RenderableSystem;

    public override void updateComponent(ref Renderable renderable, SimObject object)
    {
        renderer.setColor(object.position, renderable.color);
    }
}