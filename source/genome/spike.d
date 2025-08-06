module genome.spike;

import genome.simobject;
import genome.map;
import genome.rendering;
import genome.settings.config;
import std.random;

struct Spike
{
public:
    int aliveFrames;
}

@AddAtStart
public class SpawnSpikeSystem : BaseSystem
{
    mixin CreateMethod!SpawnSpikeSystem;
    private enum float baseSpawnFrequency = 0.001;

    public override void update()
    {
        for(int y = 0; y < gsic.xMapSize; y++)
        {
            for (int x = 0; x < gsic.xMapSize; x++)
            {
                auto object = map.getAtPosition([x, y]);   
                if (canSpawnSpike(object) && uniform01() <= gsc.spikeSpawnFrequency * baseSpawnFrequency)
                {
                    object.addComponent!Spike(Spike.init);
                }
            }
        }
    }

    //I repeat myself, but I don't know where to put this thing
    private bool canSpawnSpike(SimObject object)
    {
        import genome.agent, genome.food;
        if(object.hasComponent!Agent() || object.hasComponent!Food() || object.hasComponent!Spike())
        {
            return false;
        }

        return true;
    }
}

@AddAtStart
public class SpikeSystem : ObjectSystem!Spike
{
    mixin CreateMethod!SpikeSystem;
    private enum Color spikeColor = colorFromHEX!0xAEAEAE;
    private enum int maxAliveFrames = 100;

    public this()
    {
        color = spikeColor;
    }
    

    public override void updateObject(ref Spike spike, SimObject object)
    {
        if(spike.aliveFrames >= gsc.maxSpikeAliveFrames) object.removeComponent!Spike();

        spike.aliveFrames++;
    }
}