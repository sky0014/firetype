package de.maxdidit.hardware.font 
{
	import de.maxdidit.hardware.font.data.tables.truetype.glyf.contours.Vertex;
	import de.maxdidit.list.CircularLinkedList;
	import de.maxdidit.list.elements.UnsignedIntegerListElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	/**
	 * ...
	 * @author Max Knoblich
	 */
	public class HardwareGlyph 
	{
		///////////////////////
		// Member Fields
		///////////////////////
		
		private var vertexBuffer:VertexBuffer3D;
		private var indexBuffer:IndexBuffer3D;
		
		private var numTriangles:uint;
		
		///////////////////////
		// Constructor
		///////////////////////
		
		public function HardwareGlyph() 
		{
			
		}
		
		///////////////////////
		// Member Functions
		///////////////////////
		
		public function initialize(paths:Vector.<Vector.<Vertex>>, context3d:Context3D):void
		{
			var path:Vector.<Vertex> = connectAllPaths(paths);
			
			var indices:Vector.<uint> = triangulatePath(path);
			var vertexData:Vector.<Number> = createVertexData(path);
			
			vertexBuffer = context3d.createVertexBuffer(path.length, 3);
			vertexBuffer.uploadFromVector(vertexData, 0, path.length);
			
			indexBuffer = context3d.createIndexBuffer(indices.length);
			indexBuffer.uploadFromVector(indices, 0, indices.length);
			
			numTriangles = indices.length / 3;
		}
		
		public function render(context3d:Context3D):void
		{
			context3d.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3d.drawTriangles(indexBuffer, 0, numTriangles);
		}
		
		private function createVertexData(path:Vector.<Vertex>):Vector.<Number> 
		{
			const l:uint = path.length;
			var result:Vector.<Number> = new Vector.<Number>(l * 3);
			
			for (var i:uint = 0; i < l; i++)
			{
				var index:uint = i * 3;
				var vertex:Vertex = path[i];
				
				result[index] = vertex.x;
				result[index + 1] = vertex.y;
				result[index + 2] = 0;
			}
			
			return result;
		}
		
		private function triangulatePath(path:Vector.<Vertex>):Vector.<uint> 
		{
			const l:uint = path.length;
			
			// create index array
			var availableIndices:CircularLinkedList = new CircularLinkedList();
			for (var i:uint = 0; i < l; i++)
			{
				availableIndices.addElement(new UnsignedIntegerListElement(i));
			}
			
			// ear clipping algorithm
			
			var result:Vector.<uint> = new Vector.<uint>();
			
			var currentVertex:Vertex;
			var previousVertex:Vertex;
			var nextVertex:Vertex;
			
			var currentIndex:UnsignedIntegerListElement = availableIndices.firstElement as UnsignedIntegerListElement;
			
			var iterations:int = 0; // temporary variable
			
			while (availableIndices.numElements >= 3 && iterations < 2000)
			{	
				currentVertex = path[currentIndex.value];
				previousVertex = path[(currentIndex.previous as UnsignedIntegerListElement).value];
				nextVertex = path[(currentIndex.next as UnsignedIntegerListElement).value];
				
				var toPreviousX:Number = previousVertex.x - currentVertex.x;
				var toPreviousY:Number = previousVertex.y - currentVertex.y;
				
				var toNextX:Number = nextVertex.x - currentVertex.x;
				var toNextY:Number = nextVertex.y - currentVertex.y;
				
				// test if current vertex is part of convex hull
				var crossProduct:Number = toPreviousX * toNextY - toPreviousY * toNextX;
				
				if (crossProduct <= 0)
				{
					// iterate
					currentIndex = currentIndex.next as UnsignedIntegerListElement;
				
					iterations++;
					continue;
				}
				
				if (containsAnyPointFromPath(path, previousVertex, currentVertex, nextVertex, currentIndex.next.next as UnsignedIntegerListElement, currentIndex.previous as UnsignedIntegerListElement))
				{
					// iterate
					currentIndex = currentIndex.next as UnsignedIntegerListElement;
				
					iterations++;
					continue;
				}
				
				// add triangle to result
				result.push((currentIndex.previous as UnsignedIntegerListElement).value);
				result.push(currentIndex.value);
				result.push((currentIndex.next as UnsignedIntegerListElement).value);
				
				// remove current index
				availableIndices.removeElement(currentIndex);
				
				currentIndex = availableIndices.firstElement as UnsignedIntegerListElement;
			}
			
			return result;
		}
		
		private function containsAnyPointFromPath(path:Vector.<Vertex>, vertexA:Vertex, vertexB:Vertex, vertexC:Vertex, startElement:UnsignedIntegerListElement, endElement:UnsignedIntegerListElement):Boolean 
		{
			var currentElement:UnsignedIntegerListElement = startElement;
			
			while (currentElement != endElement)
			{
				var currentVertex:Vertex = path[currentElement.value];
				
				if (isInsideTriangle(currentVertex, vertexA, vertexB, vertexC))
				{
					return true;
				}
				
				currentElement = currentElement.next as UnsignedIntegerListElement;
			}
			
			return false;
		}
		
		private function isInsideTriangle(currentVertex:Vertex, vertexA:Vertex, vertexB:Vertex, vertexC:Vertex):Boolean 
		{
			// source: http://www.blackpawn.com/texts/pointinpoly/
			
			const v0_x:Number = vertexC.x - vertexA.x;
			const v0_y:Number = vertexC.y - vertexA.y;
			
			const v1_x:Number = vertexB.x - vertexA.x;
			const v1_y:Number = vertexB.y - vertexA.y;
			
			const v2_x:Number = currentVertex.x - vertexA.x;
			const v2_y:Number = currentVertex.y - vertexA.y;
			
			const dot00:Number = v0_x * v0_x + v0_y * v0_y;
			const dot01:Number = v0_x * v1_x + v0_y * v1_y;
			const dot02:Number = v0_x * v2_x + v0_y * v2_y;
			const dot11:Number = v1_x * v1_x + v1_y * v1_y;
			const dot12:Number = v1_x * v2_x + v1_y * v2_y;
			
			const inverseDenominator:Number = 1 / (dot00 * dot11 - dot01 * dot01);
			const u:Number = inverseDenominator * (dot11 * dot02 - dot01 * dot12);
			const v:Number = inverseDenominator * (dot00 * dot12 - dot01 * dot02);
			
			return (u > 0) && (v > 0) && (u + v <= 1);
		}
		
		private function connectAllPaths(paths:Vector.<Vector.<Vertex>>):Vector.<Vertex> 
		{
			var firstPath:Vector.<Vertex> = paths[0];
			const l:uint = paths.length;
			
			var result:Vector.<Vertex> = firstPath;
			
			// connect first path to other paths
			// find closest vertices in paths
			for (var i:uint = 1; i < l; i++)
			{
				result = connectPaths(result, paths[i]);
			}
			
			return result;
		}
		
		private function connectPaths(pathA:Vector.<Vertex>, pathB:Vector.<Vertex>):Vector.<Vertex>
		{
			var result:Vector.<Vertex> = new Vector.<Vertex>();
			
			// find shortest distance between vertices
			const lA:uint = pathA.length;
			const lB:uint = pathB.length;
			
			var smallestA:uint = 0;
			var smallestB:uint = 0;
			var smallestDistance:Number = Number.MAX_VALUE;
			
			for (var a:uint = 0; a < lA; a++)
			{
				var vertexA:Vertex = pathA[a];
				
				for (var b:uint = 0; b < lB; b++)
				{
					var vertexB:Vertex = pathB[b];
					
					var dX:Number = vertexB.x - vertexA.x;
					var dY:Number = vertexB.y - vertexA.y;
					
					var distance:Number = dX * dX + dY * dY;
					if (distance < smallestDistance)
					{
						smallestA = a;
						smallestB = b;
						smallestDistance = distance;
					}
				}
			}
			
			// fill result
			// fill up to bridge vertex in A
			for (var i:uint = 0; i <= smallestA; i++)
			{
				result.push(pathA[i]);
			}
			
			// fill from bridge vertex in B till end
			for (i = smallestB; i < lB; i++)
			{
				result.push(pathB[i]);
			}
			
			// fill from beginning to bridge vertex in B
			for (i = 0; i <= smallestB; i++)
			{
				result.push(pathB[i]);
			}
			
			// fill from bridge vertex in A till end
			for (i = smallestA; i < lA; i++)
			{
				result.push(pathA[i]);
			}
			
			return result;
		}
	}

}