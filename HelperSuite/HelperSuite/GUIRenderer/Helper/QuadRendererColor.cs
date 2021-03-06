
#region Using Statements

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

#endregion

namespace ModelViewer.HelperSuite.GUIRenderer.Helper
{
    public class QuadRendererColor
    {
        //buffers for rendering the quad
        private readonly VertexPositionColor[] _vertexBuffer;
        private readonly short[] _indexBuffer;

        public QuadRendererColor()
        {
            //_vertexBuffer = new VertexPositionTexture[4];
            //_vertexBuffer[0] = new VertexPositionTexture(new Vector3(-1, 1, 1), new Vector2(0, 0));
            //_vertexBuffer[1] = new VertexPositionTexture(new Vector3(1, 1, 1), new Vector2(1, 0));
            //_vertexBuffer[2] = new VertexPositionTexture(new Vector3(-1, -1, 1), new Vector2(0, 1));
            //_vertexBuffer[3] = new VertexPositionTexture(new Vector3(1, -1, 1), new Vector2(1, 1));
            _vertexBuffer = new VertexPositionColor[4];
            _vertexBuffer[0] = new VertexPositionColor(new Vector3(-1, 1, 1), Color.White);
            _vertexBuffer[1] = new VertexPositionColor(new Vector3(1, 1, 1), Color.White);
            _vertexBuffer[2] = new VertexPositionColor(new Vector3(-1, -1, 1), Color.White);
            _vertexBuffer[3] = new VertexPositionColor(new Vector3(1, -1, 1), Color.White);
            _indexBuffer = new short[] { 0, 3, 2, 0, 1, 3 };
        }

        public void RenderQuad(GraphicsDevice graphicsDevice, Vector2 v1, Vector2 v2)
        {
            //bot left
            _vertexBuffer[0].Position.X = v1.X;
            _vertexBuffer[0].Position.Y = v2.Y;
            _vertexBuffer[0].Color = Color.Black;

            //bot right
            _vertexBuffer[1].Position.X = v2.X;
            _vertexBuffer[1].Position.Y = v2.Y;
            _vertexBuffer[1].Color = Color.White;

            //Top left
            _vertexBuffer[2].Position.X = v1.X;
            _vertexBuffer[2].Position.Y = v1.Y;
            _vertexBuffer[2].Color = Color.Black;

            //Top right
            _vertexBuffer[3].Position.X = v2.X;
            _vertexBuffer[3].Position.Y = v1.Y;
            _vertexBuffer[3].Color = Color.Blue;

            graphicsDevice.DrawUserIndexedPrimitives
                (PrimitiveType.TriangleList, _vertexBuffer, 0, 4, _indexBuffer, 0, 2);
        }

    }
}
