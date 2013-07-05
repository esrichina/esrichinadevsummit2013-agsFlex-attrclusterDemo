package com.esri.myattrcluster
{
import com.esri.ags.clusterers.supportClasses.Cluster;
import com.esri.ags.geometry.MapPoint;

public class AttrCluster extends Cluster
{
    public var attr:String;

    public function AttrCluster(center:MapPoint = null, weight:Number = 0.0, graphics:Array = null, attr:String = null)
    {
        super(center, weight, graphics);
        this.attr = attr;
    }
}
}