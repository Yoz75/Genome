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