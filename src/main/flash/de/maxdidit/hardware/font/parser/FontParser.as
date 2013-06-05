package de.maxdidit.hardware.font.parser 
{
	import de.maxdidit.hardware.font.data.HardwareFontData;
	import de.maxdidit.hardware.font.events.FontEvent;
	import de.maxdidit.hardware.font.HardwareFont;
	import de.maxdidit.hardware.font.triangulation.ITriangulator;
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Max Knoblich
	 */
	public class FontParser extends EventDispatcher implements IFontParser
	{
		///////////////////////
		// Member Fields
		///////////////////////
		
		private var _loaderQueue:Vector.<FontLoaderJob> = new Vector.<FontLoaderJob>();
		private var _currentJob:FontLoaderJob;
		
		///////////////////////
		// Constructor
		///////////////////////
		
		public function FontParser() 
		{
		}
		
		///////////////////////
		// Member Properties
		///////////////////////
		
		///////////////////////
		// Member Functions
		///////////////////////
		
		public function loadFont(url:String):EventDispatcher
		{
			var fontLoaderJob:FontLoaderJob = new FontLoaderJob();
			fontLoaderJob.url = url;
			_loaderQueue.push(fontLoaderJob);
			
			if (!_currentJob)
			{
				loadNextJob();
			}
			
			return fontLoaderJob;
		}
		
		private function loadNextJob():void 
		{	
			if (_loaderQueue.length == 0)
			{
				_currentJob = null;
				return;
			}
			
			_currentJob = _loaderQueue.shift();
			
			_currentJob.addEventListener(Event.COMPLETE, handleFontLoaded);
			_currentJob.loadFont(_currentJob.url);
		}
		
		public function parseFont(data:ByteArray):HardwareFont
		{
			var hardwareFont:HardwareFont = new HardwareFont();
			
			hardwareFont.data = parseFontData(data);
			hardwareFont.finalize();
			
			return hardwareFont;
		}
		
		protected function parseFontData(data:ByteArray):HardwareFontData
		{
			throw new Error("Function not implemented. Extend FontParser and implement function.");
			return null;
		}
		
		///////////////////////
		// Event Handler
		///////////////////////
		
		private function handleFontLoaded(e:Event):void 
		{
			// TODO: provide feedback that font has been loaded.
			var fontLoaderJob:FontLoaderJob = e.target as FontLoaderJob;
			
			var urlLoader:URLLoader = fontLoaderJob.urlLoader;
			
			var data:ByteArray = urlLoader.data as ByteArray;
			var font:HardwareFont = parseFont(data);
			
			fontLoaderJob.dispatchEvent(new FontEvent(FontEvent.FONT_PARSED, font));
			dispatchEvent(new FontEvent(FontEvent.FONT_PARSED, font));
			
			loadNextJob();
		}
		
		private function handleFontLoadingFailed(e:Event):void 
		{	
			var fontLoaderJob:FontLoaderJob = e.target as FontLoaderJob;
			var urlLoader:URLLoader = fontLoaderJob.urlLoader;
			
			loadNextJob();
		}
	}

}