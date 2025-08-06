module genome.dumping;

import genome.simobject;
import genome.settings.config;
import genome.input;
import genome.agent : Agent;
import std.range : iota;
import std.file;
import std.array : appender;
import std.conv : to;

@AddAtStart
public class DumpSystem : BaseSystem
{
    mixin CreateMethod!DumpSystem;

    alias AgentsPool = ComponentPool!Agent;

    enum string dumpFileName = "dump.txt";

    public override void update()
    {
        if(!Input.IsKeyDown(Keys.t)) return;

        auto stringBuilder = appender!string;
        string dumbContent;

        foreach (i; iota(0, gsic.xMapSize * gsic.yMapSize))
        {
            SimObject object = SimObject(i);
            if(!AgentsPool.instance.hasComponent(object)) continue;

            Agent agent = AgentsPool.instance.getComponent(object);

            foreach (j, instruction; agent.genome)
            {                
                stringBuilder.put("№");
                stringBuilder.put(to!string(j));
                stringBuilder.put(" ");
                stringBuilder.put(to!string(instruction));
                stringBuilder.put(" ");
                stringBuilder.put(to!size_t(instruction).to!string);
                stringBuilder.put("\n");
            }

            stringBuilder.put("\n\n");
        }

        dumbContent = stringBuilder.data();

        write(dumpFileName, dumbContent);
    }
}