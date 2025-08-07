module genome.simulation;

import genome.simobject;
import genome.map;
import genome.rendering;
import genome.settings.config;
import std.traits;

/// Genome simulation
public struct Simulation
{
    private bool shouldRestart;

    /// Run the Genome
    public void run()
    {
        import genome.food;
        import std.random;

        renderer.createWindow("wow!");

        while(!renderer.shouldEndDrawing())
        {
            map.initMe();
            shouldRestart = false;
            for(int i = 0; i < gsic.xMapSize; i++)
            {
                for(int j = 0; j < gsic.xMapSize; j++)
                {
                    auto object = map.getAtPosition([j, i]);

                    Renderable renderable;
                    renderable.color = Color(0, 0, 0);

                    object.addComponent!Renderable(renderable);
                }
            }

            addSystems();
            while(!shouldRestart) update;
        }
    }

    /// Fully restart current simulation
    public void restart()
    {
        foreach(system; systems)
        {
            system.destroy();
        }

        systems.length = 0;
        shouldRestart = true;
    }

    private void update()
    {
        foreach (system; systems)
        {
            system.update();
        }

        renderer.update();
    }    


    private void addSystems()
    {
        import genome.agent, genome.rendering, genome.food, genome.spike, genome.dumping, genome.updating;

        addSystemsFromModule!(genome.agent)();
        addSystemsFromModule!(genome.rendering)();
        addSystemsFromModule!(genome.food)();
        addSystemsFromModule!(genome.spike)();
        addSystemsFromModule!(genome.dumping)();
        addSystemsFromModule!(genome.updating)();
    }

    private void addSystemsFromModule(alias moduleName)()
    {
        import std.traits;

        static foreach (i, attributed; getSymbolsByUDA!(moduleName, AddAtStart))
        {            
            attributed.create().simulation = &this;            
        }
    }
}