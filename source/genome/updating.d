module genome.updating;

import genome.simobject;
import genome.input;
import genome.settings.manager : configManager;

@AddAtStart
public class UpdateConfigSystem : BaseSystem
{
    mixin CreateMethod!UpdateConfigSystem;
    
    public override void update()
    {
        if(!Input.IsKeyDown(Keys.q)) return;

        configManager.updateConfigs();
    }
}

@AddAtStart
public class RestartSimulationSystem : BaseSystem
{
    mixin CreateMethod!RestartSimulationSystem;

    public override void update()
    {
        if(!Input.IsKeyDown(Keys.r)) return;

        simulation.restart();
    }
}

@AddAtStart
public class ExitSimulationSystem : BaseSystem
{
    mixin CreateMethod!ExitSimulationSystem;

    public override void update()
    {
        import core.stdc.stdlib : exit;

        if(!Input.IsKeyDown(Keys.escape)) return;

        exit(0);
    }
}