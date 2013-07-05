package com.esri.myattrcluster
{
import com.esri.ags.Graphic;
import com.esri.ags.Map;
import com.esri.ags.clusterers.ESRIClusterer;
import com.esri.ags.geometry.Extent;
import com.esri.ags.geometry.MapPoint;
import com.esri.ags.layers.GraphicsLayer;

import flash.utils.Dictionary;

import mx.collections.ArrayCollection;

public class AttrClusterer extends ESRIClusterer
{

    [Bindable]
    public var attrName:String;

    private var m_center:MapPoint;

    private var m_clusterDistance2:Number;

    private var m_clusterHeight:Number;

    private var m_clusterWidth:Number;

    private var m_extentHeight:Number;

    private var m_extentWidth:Number;

    private var m_graphicWeightFunction:Function = graphicWeightPrivate;

    private var m_orig /*<String,AttrCluster>*/:Dictionary;

    private var m_overlapExists:Boolean;
	
	private var m_overallMinCount:Number;
	
	private var m_overallMaxCount:Number;
	
	private var m_overallMinWeight:Number;

	private var m_overallMaxWeight:Number;
	
    public function AttrClusterer()
    {
    }

    override public function clusterGraphics(graphicsLayer:GraphicsLayer, graphicCollection:ArrayCollection):Array
    {
        const arrOfGraphics:Array = [];

        initializeOverallValues();

        const map:Map = graphicsLayer.map;

        if (m_center === null)
        {
            m_center = map.extent.center;
        }

        const extent:Extent = map.extent.expand(m_extentExpandFactor);
        m_extentWidth = extent.width;
        m_extentHeight = extent.height;

        m_clusterWidth = m_sizeInPixels * map.extent.width / map.width;
        m_clusterHeight = m_sizeInPixels * map.extent.height / map.height;
        m_clusterDistance2 = m_clusterWidth * m_clusterWidth + m_clusterHeight * m_clusterHeight;

        convertGraphicsToClusters(graphicCollection, arrOfGraphics, extent);
        do // Keep merging overlapping clusters until none overlap.
        {
            mergeOverlappingClusters();
        } while (m_overlapExists);

        for each (var cluster:AttrCluster in m_orig)
        {
            // Convert clusters to graphics so they can be displayed.
            createClusterGraphic(cluster, arrOfGraphics);
            m_overallMinCount = Math.min(m_overallMinCount, cluster.graphics.length);
            m_overallMaxCount = Math.max(m_overallMaxCount, cluster.graphics.length);
            m_overallMinWeight = Math.min(m_overallMinCount, cluster.weight);
            m_overallMaxWeight = Math.max(m_overallMaxCount, cluster.weight);
        }
        return arrOfGraphics;
    }

    override public function destroy(graphicsLayer:GraphicsLayer):void
    {
        m_center = null;
        m_orig = null;
    }

    [Bindable]
    public function get graphicWeightFunction():Function
    {
        return m_graphicWeightFunction === graphicWeightPrivate ? null : m_graphicWeightFunction;
    }

    public function set graphicWeightFunction(value:Function):void
    {
        if (m_graphicWeightFunction !== value)
        {
            m_graphicWeightFunction = value === null ? graphicWeightPrivate : value;
            dispatchEventChange();
        }
    }

    private function convertGraphicsToClusters(inputGraphics:ArrayCollection, arrOfGraphics:Array, extent:Extent):void
    {
        m_orig = new Dictionary();
        for each (var graphic:Graphic in inputGraphics)
        {
            if (graphic.visible === false)
            {
                continue;
            }
            // Convert graphic to map point
            const mapPoint:MapPoint = m_graphicToMapPointFunction(graphic);
            if (mapPoint)
            {
                // Cluster only graphics in the map extent + extentExpandBuffer
                if (extent.contains(mapPoint))
                {
                    const cx:int = toClusterX(mapPoint.x);
                    const cy:int = toClusterY(mapPoint.y);

                    // Convert to cluster dictionary key.
                    const ci:String = cx + '_' + cy + '_' + graphic.attributes[attrName];

                    // Find existing cluster
                    var cluster:AttrCluster = m_orig[ci];
                    if (cluster)
                    {
                        // Average centroid values based on new map point.
                        const mapPointWeight:Number = m_graphicWeightFunction(graphic);
                        const totalWeight:Number = cluster.weight + mapPointWeight;
                        cluster.center.x = (cluster.center.x * cluster.weight + mapPoint.x * mapPointWeight) / totalWeight;
                        cluster.center.y = (cluster.center.y * cluster.weight + mapPoint.y * mapPointWeight) / totalWeight;
                        cluster.weight = totalWeight;
                        cluster.graphics.push(graphic);
                    }
                    else
                    {
                        // Not found - create a new cluster as that index.
                        m_orig[ci] = new AttrCluster(new MapPoint(mapPoint.x, mapPoint.y), m_graphicWeightFunction(graphic), [ graphic ], graphic.attributes[attrName]);
                    }
                }
            }
            else
            {
                arrOfGraphics.push(graphic);
            }
        }
    }

    private function graphicWeightPrivate(graphic:Graphic):Number
    {
        return 1.0;
    }

    /**
     * Adjust centroid weighted by the number of map points in the cluster.
     * The more map points a cluster has, the less it moves.
     *
     * @private
     */
    private function merge(lhs:AttrCluster, rhs:AttrCluster):void
    {
        const totalWeight:Number = lhs.weight + rhs.weight;
        lhs.center.x = (lhs.weight * lhs.center.x + rhs.weight * rhs.center.x) / totalWeight;
        lhs.center.y = (lhs.weight * lhs.center.y + rhs.weight * rhs.center.y) / totalWeight;
        lhs.weight += rhs.weight;

        // Move over the graphics.
        while (rhs.graphics.length)
        {
            lhs.graphics.push(rhs.graphics.pop());
        }

        // mark the cluster as merged.
        rhs.graphics = null;
    }

    private function mergeOverlappingClusters():void
    {
        m_overlapExists = false;
        // Create a new set to hold non-overlapping clusters.
        const dest:Dictionary = new Dictionary(); // int,Cluster
        for each (var cluster:AttrCluster in m_orig)
        {
            // keep merging clusters with graphics.
            if (cluster.graphics)
            {
                const cx:int = toClusterX(cluster.center.x);
                const cy:int = toClusterY(cluster.center.y);
                // Search all immediately adjacent clusters.
                searchAndMerge(cluster, cx + 1, cy + 0);
                searchAndMerge(cluster, cx - 1, cy + 0);
                searchAndMerge(cluster, cx + 0, cy + 1);
                searchAndMerge(cluster, cx + 0, cy - 1);
                searchAndMerge(cluster, cx + 1, cy + 1);
                searchAndMerge(cluster, cx + 1, cy - 1);
                searchAndMerge(cluster, cx - 1, cy + 1);
                searchAndMerge(cluster, cx - 1, cy - 1);

                // Find the new cluster centroid values.
                const nx:int = toClusterX(cluster.center.x);
                const ny:int = toClusterY(cluster.center.y);
                // Compute new dictionary key.
                const ni:String = nx + '_' + ny + '_' + cluster.attr;
                dest[ni] = cluster;
            }
        }
        m_orig = dest;
    }

    private function searchAndMerge(cluster:AttrCluster, cx:int, cy:int):void
    {
        const ci:String = cx + '_' + cy + '_' + cluster.attr;
        const found:AttrCluster = m_orig[ci];
        if (found && found.graphics)
        {
            // Compute Euclidian distance.
            const dx:Number = cluster.center.x - found.center.x;
            const dy:Number = cluster.center.y - found.center.y;
            const dd:Number = dx * dx + dy * dy;
            // Check if there is a overlap based on distance.
            if (dd < m_clusterDistance2)
            {
                m_overlapExists = true;
                merge(cluster, found);
            }
        }
    }

    private function toClusterX(x:Number):int
    {
        return Math.floor((x - m_center.x) / m_clusterWidth);//m_clusterWidth代表聚合单元的地图距离
    }

    private function toClusterY(y:Number):int
    {
        return Math.floor((y - m_center.y) / m_clusterHeight);
    }
}

}