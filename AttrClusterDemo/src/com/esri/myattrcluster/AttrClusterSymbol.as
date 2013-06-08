package com.esri.myattrcluster
{
import com.esri.ags.Map;
import com.esri.ags.clusterers.supportClasses.ClusterGraphic;
import com.esri.ags.geometry.Geometry;
import com.esri.ags.geometry.MapPoint;
import com.esri.ags.symbols.Symbol;

import flash.display.Sprite;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import mx.core.FlexGlobals;

public class AttrClusterSymbol extends Symbol
{
    private const GREEN:Number = 0x76D100;

    private const ORANGE:Number = 0xFF6900;

    private const RED:Number = 0xFF0F00;

    private const YELLOW:Number = 0xFF9F00;

    private var m_textFormat:TextFormat = new TextFormat("Helvetica", 12, 0xFFFFFF);

    override public function clear(sprite:Sprite):void
    {
        sprite.graphics.clear();
    }

    override public function destroy(sprite:Sprite):void
    {
        removeAllChildren(sprite);
        sprite.x = 0;
        sprite.y = 0;
    }

    override public function draw(sprite:Sprite, geometry:Geometry, attributes:Object, map:Map):void
    {
        const clusterGraphic:ClusterGraphic = sprite as ClusterGraphic;
        if (clusterGraphic)
        {
            const n:Number = clusterGraphic.cluster.weight;
            const attr:String = attributes.attr;
            const textField:TextField = sprite.getChildByName("textField") as TextField;
          
			if (n > 1)
			{
				textField.text = "  " +n.toString()+"  ";
			}
			else
			{
				textField.text = "   ";
			}
            if (m_textFormat)
            {
                textField.embedFonts = FlexGlobals.topLevelApplication.systemManager.isFontFaceEmbedded(m_textFormat);
                textField.setTextFormat(m_textFormat);
            }
            textField.x = -2 - (textField.textWidth >> 1);
            textField.y = -1 - (textField.textHeight >> 1);

            const mapPoint:MapPoint = clusterGraphic.mapPoint;
            sprite.x = toScreenX(map, mapPoint.x);
            sprite.y = toScreenY(map, mapPoint.y);

            if (n === 1)
            {
				
				sprite.graphics.beginFill(0x00000000, 0.75);
				sprite.graphics.drawCircle(0, 0, textField.textWidth * 0.6 + 1);
				sprite.graphics.endFill();
                sprite.graphics.beginFill(0x00FF0000, 0.5);
                sprite.graphics.drawCircle(0, 0, textField.textWidth * 0.6);
                sprite.graphics.endFill();
            }
            else
            {
                var color:Number;
//                if (n < 6)
//                {
//                    color = GREEN;
//                }
//                else if (n < 11)
//                {
//                    color = YELLOW;
//                }
//                else if (n < 21)
//                {
//                    color = ORANGE;
//                }
	           if (attr.length==1)
                {
					   color = GREEN;
				 }
                else
                {
                    color = RED;
                }

                sprite.graphics.beginFill(0x00000000, 0.75);
                sprite.graphics.drawCircle(0, 0, textField.textWidth * 0.6 + 1);
                sprite.graphics.endFill();

                sprite.graphics.beginFill(color, 0.75);
//                sprite.graphics.drawCircle(0, 0, textField.textWidth * 0.6);
				sprite.graphics.drawCircle(0, 0, textField.textWidth * 0.6);
                sprite.graphics.endFill();

            }
        }
    }

    override public function initialize(sprite:Sprite, geometry:Geometry, attributes:Object, map:Map):void
    {
        if (sprite is ClusterGraphic)
        {
            const textField:TextField = new TextField();
            textField.name = "textField";
            textField.mouseEnabled = false;
            textField.mouseWheelEnabled = false;
            textField.antiAliasType = AntiAliasType.ADVANCED;
            textField.selectable = false;
            textField.autoSize = TextFieldAutoSize.CENTER;
            sprite.addChild(textField);
        }
    }

    [Bindable]
    /**
     * The text format.
     *
     * @default null
     */
    public function get textFormat():TextFormat
    {
        return m_textFormat;
    }

    /**
     * @private
     */
    public function set textFormat(value:TextFormat):void
    {
        if (m_textFormat !== value)
        {
            m_textFormat = value;
            dispatchEventChange();
        }
    }
}

}