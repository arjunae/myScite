/**
 * ActionScript Math Examples
 * ---------------------
 * VERSION: 1.0
 * DATE: 12/12/2010
 * AS3
 * UPDATES AND DOCUMENTATION AT: http://www.freeactionscript.com/2010/12/actionscript-math-and-trigonometry
 **/
package  
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	public class Main extends MovieClip
	{
		// Properties		
		public var startX:Number;
		public var startY:Number;
		public var dragging:Boolean = false;
		
		/**
		 * Constructor
		 */
		public function Main() 
		{
			trace("Main");
			
			// set center of drag area
			startX = circle.x;
			startY = circle.y;
			
			// add mouse listeners
			circle.addEventListener(MouseEvent.MOUSE_DOWN, dragPressHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, dragReleaseHandler);
			
			// make circle behave like a button (hand cursor)
			circle.buttonMode = true;
			
			// add enter frame event
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		/**
		 * Main loop - repeats every frame
		 * @param	event
		 */
		protected function enterFrameHandler(event:Event):void
		{
			var dx:Number = circle.x - startX;
			var dy:Number = circle.y - startY;
			
			// Calculate distance from starting point
			distanceTxt.text = String(getDistance(dx, dy));
			
			// Calculate the angle from the starting point in radians
			radiansTxt.text = String(getRadians(dx, dy));
			
			// Convert radians to degrees
			degreesTxt.text = String(getDegrees(getRadians(dx, dy)));
			
			// rotate arrow
			arrow.rotation = getDegrees(getRadians(dx, dy));
			circle.rotation = getDegrees(getRadians(dx, dy)) + 180;
			
			// Show x and y 
			xTxt.text = String(dx);
			yTxt.text = String(dy);
			
			drawLine();
		}
		
		/**
		 * Draws lines
		 */
		private function drawLine():void
		{
			// draw line from center to circle
			this.graphics.clear();
			this.graphics.lineStyle(2, 0x00CC00, .5, true);
			this.graphics.moveTo(startX, startY);
			this.graphics.lineTo(circle.x, circle.y);
			
			// draw line top to bottom
			this.graphics.lineStyle(1, 0xA2EEF7, .5, true);
			this.graphics.moveTo(circle.x, container.y);
			this.graphics.lineTo(circle.x, container.height + container.y);
			
			// draw line left to right
			this.graphics.lineStyle(1, 0xA2EEF7, .5, true);
			this.graphics.moveTo(container.x, circle.y);
			this.graphics.lineTo(container.width + container.x, circle.y);
		}
		
		/**
		 * Mouse Press handler
		 * @param	event
		 */
		protected function dragPressHandler(event:MouseEvent):void
		{
			// Create a rectangle to constrain the drag
			var rx:Number = container.x + circle.width/2;
			var ry:Number = container.y + circle.height/2;
			var rw:Number = container.width - circle.width;
			var rh:Number = container.height - circle.height;
			var rect:Rectangle = new Rectangle(rx, ry, rw, rh);
			
			dragging = true;
			circle.startDrag(false,rect);
		}
		
		/**
		 * Mouse Release handler
		 * @param	event
		 */
		protected function dragReleaseHandler(event:MouseEvent):void
		{
			if (dragging)
			{
				dragging = false;
				circle.stopDrag();
			}
		}
		
		/**
		 * Get distance
		 * @param	delta_x
		 * @param	delta_y
		 * @return
		 */
		public function getDistance(delta_x:Number, delta_y:Number):Number
		{
			return Math.sqrt((delta_x*delta_x)+(delta_y*delta_y));
		}
		
		/**
		 * Get radians
		 * @param	delta_x
		 * @param	delta_y
		 * @return
		 */
		public function getRadians(delta_x:Number, delta_y:Number):Number
		{
			var r:Number = Math.atan2(delta_y, delta_x);
			
			if (delta_y < 0)
			{
				r += (2 * Math.PI);
			}
			return r;
		}
		
		/**
		 * Get degrees
		 * @param	radians
		 * @return
		 */
		public function getDegrees(radians:Number):Number
		{
			return Math.floor(radians/(Math.PI/180));
		}
	}
	
}