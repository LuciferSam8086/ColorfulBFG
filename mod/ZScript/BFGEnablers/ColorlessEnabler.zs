// Empty class, just in case the items should do something in common
// An Enabler permits the colorful BFG to shoot a specific ball
// Maybe in future I will find better sprites :)
class ColorlessEnabler : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}