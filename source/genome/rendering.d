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

    private Camera2D camera;
    private Image simScreen;
    private Texture2D simScreenTexture;

    //Idk how to name it
    private float requestedZoom;

    /// Create window
    /// Params:
    ///   title = window title
    public void createWindow(string title)
    {
        immutable int width = GetScreenWidth();
        immutable int height = GetScreenHeight();

        SetConfigFlags(ConfigFlags.FLAG_WINDOW_UNDECORATED);
        InitWindow(width, height, title.ptr);

        simScreen = GenImageColor(gsic.xMapSize, gsic.yMapSize, Colors.BLACK);
        simScreenTexture = LoadTextureFromImage(simScreen);

        camera.target = Vector2(0, 0);
        camera.offset = Vector2(width / 2, height / 2);
        camera.rotation = 0;
        camera.zoom = 1.0f;

        requestedZoom = 0;
    }

    public void setColor(int[2] position, Color color)
    {
        ImageDrawPixel(&simScreen, position[0], position[1], cast(raylib.Color) color);
    }

    public void update()
    {
        enum float totalZoomMultiplier = 0.075;
        enum float addZoom = 0.035;
        enum float minimalZoom = 0.1;
        
        float wheel = GetMouseWheelMove();
        if (wheel != 0)
        {
            Vector2 mouseWorldPos = GetScreenToWorld2D(GetMousePosition(), camera);
            camera.offset = GetMousePosition();
            camera.target = mouseWorldPos;
            
            float zoom = wheel * totalZoomMultiplier;

            requestedZoom += zoom;            
        }

        import std.stdio; writeln(requestedZoom);

        if(requestedZoom > 0)
        {
            requestedZoom -= addZoom;
            camera.zoom += addZoom;

            if(requestedZoom - addZoom < 0) requestedZoom = 0;
        }
        else if(requestedZoom < 0)
        {
            requestedZoom += addZoom;
            camera.zoom -= addZoom;

            if(requestedZoom + addZoom > 0) requestedZoom = 0;
        }

        if (camera.zoom < minimalZoom) camera.zoom = minimalZoom;

        immutable float moveSpeed = 100.0f * GetFrameTime() / camera.zoom;
        if (Input.IsKeyDown(Keys.w)) camera.target.y -= moveSpeed;
        if (Input.IsKeyDown(Keys.s)) camera.target.y += moveSpeed;
        if (Input.IsKeyDown(Keys.a)) camera.target.x -= moveSpeed;
        if (Input.IsKeyDown(Keys.d)) camera.target.x += moveSpeed;

        BeginDrawing();
        ClearBackground(Colors.BLACK);
        BeginMode2D(camera);

        UpdateTexture(simScreenTexture, simScreen.data);
        DrawTexture(simScreenTexture, 0, 0, Colors.RAYWHITE);     

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