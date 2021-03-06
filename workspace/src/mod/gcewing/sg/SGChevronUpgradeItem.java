//------------------------------------------------------------------------------------------------
//
//   SG Craft - Chevron upgrade item
//
//------------------------------------------------------------------------------------------------

package gcewing.sg;

import net.minecraft.block.*;
import net.minecraft.item.*;
import net.minecraft.entity.player.*;
import net.minecraft.util.*;
import net.minecraft.util.math.*;
import net.minecraft.world.*;

public class SGChevronUpgradeItem extends Item {

    @Override
    public EnumActionResult onItemUse(ItemStack stack, EntityPlayer player, World world,
        BlockPos pos, EnumHand hand, EnumFacing side, float hitX, float hitY, float hitZ)
    {
        System.out.printf("SGChevronUpgradeItem.onItemUse: at %s\n", pos);
        Block block = world.getBlockState(pos).getBlock();
        if (block instanceof ISGBlock) {
            SGBaseTE te = ((ISGBlock)block).getBaseTE(world, pos);
            if (te != null)
                return te.applyChevronUpgrade(stack, player);
        }
        return EnumActionResult.FAIL;
    }

}
