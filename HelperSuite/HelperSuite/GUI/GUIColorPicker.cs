﻿using System;
using System.Reflection;
using System.Text;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using ModelViewer.HelperSuite.GUIRenderer.Helper;
using ModelViewer.HelperSuite.Static;
using ModelViewer.Logic;

namespace ModelViewer.HelperSuite.GUI
{
    class GUIColorPicker : GUIBlock
    {
        protected bool IsEngaged = false;
        
        public PropertyInfo ToggleProperty;
        public FieldInfo ToggleField;
        public Object ToggleObject;

        public Color CurrentFullColor = Color.Red;
        public Color CurrentFineColor = Color.White;

        private Vector2 _mousePointerFine; 
        private Vector2 _mousePointerFull;
        private float _mousePointerLength = 5;
        private float _mousePointerThickness = 1;
        private float _mousePointerOffset = 3;

        private float _mouseFineX = 1;
        private float _mouseFineY;
        public float border = 5f;

        private SpriteFont _font;
        private StringBuilder _colorString;



        public GUIColorPicker(Vector2 position, Vector2 dimensions, Color color, SpriteFont font, int layer = 0, GUIStyle.GUIAlignment alignment = GUIStyle.GUIAlignment.None, Vector2 ParentDimensions = new Vector2()) : base(position, dimensions, color, layer, alignment, ParentDimensions)
        {
            _font = font;
            _colorString = new StringBuilder(20);

            _colorString.AppendColor(CurrentFullColor);

            _mousePointerFine = position + Vector2.One*20;
            _mousePointerFull = position + Vector2.One * 20;
        }


        public override void Draw(GUIRenderer.GUIRenderer guiRenderer, Vector2 parentPosition, Vector2 mousePosition)
        {
            guiRenderer.DrawQuad(parentPosition + Position, Dimensions, Color);

            Vector2 fullcolorPickerDimensions = new Vector2(Dimensions.X * 0.2f, Dimensions.Y);
            guiRenderer.DrawColorQuad(parentPosition + Position + 
                new Vector2(Dimensions.X - fullcolorPickerDimensions.X, 0)
                + border*Vector2.One, 
                fullcolorPickerDimensions - Vector2.One*border*2, 
                Color.White);

            Vector2 findColorPickerDimensions = new Vector2(Dimensions.X * 0.75f, Dimensions.Y * 0.75f);
            guiRenderer.DrawQuad(parentPosition + Position + border * Vector2.One, findColorPickerDimensions, Color.White);
            guiRenderer.DrawColorQuad2(parentPosition + Position + border * Vector2.One, findColorPickerDimensions, CurrentFullColor);

            guiRenderer.DrawQuad(new Vector2(parentPosition.X + Position.X + border + Dimensions.X - fullcolorPickerDimensions.X, Position.Y + parentPosition.Y + _mousePointerFull.Y - _mousePointerThickness), new Vector2(10, _mousePointerThickness*2),  Color.White);
            

            guiRenderer.DrawQuad(parentPosition + Position + border * Vector2.One + (findColorPickerDimensions + Dimensions * 0.02f) * Vector2.UnitY, new Vector2(findColorPickerDimensions.X, 30), CurrentFineColor);

            guiRenderer.DrawText(parentPosition + Position + Vector2.One + border * Vector2.One * 2 + (findColorPickerDimensions + Dimensions * 0.05f) * Vector2.UnitY, _colorString, _font, Color.Black);
            guiRenderer.DrawText(parentPosition + Position + border * Vector2.One * 2 + (findColorPickerDimensions + Dimensions*0.05f) * Vector2.UnitY, _colorString, _font, Color.White);

            Vector2 msFine = Position + parentPosition + _mousePointerFine;
            //mouse pointer
            guiRenderer.DrawQuad(msFine - new Vector2(_mousePointerLength + _mousePointerOffset, _mousePointerThickness), new Vector2(_mousePointerLength, _mousePointerThickness*2), Color.White);
            guiRenderer.DrawQuad(msFine + new Vector2(_mousePointerOffset, -_mousePointerThickness), new Vector2(_mousePointerLength, _mousePointerThickness * 2), Color.White);

            guiRenderer.DrawQuad(msFine - new Vector2(_mousePointerThickness, _mousePointerLength + _mousePointerOffset), new Vector2(_mousePointerThickness * 2,_mousePointerLength), Color.White);
            guiRenderer.DrawQuad(msFine + new Vector2(-_mousePointerThickness, _mousePointerOffset), new Vector2(_mousePointerThickness * 2, _mousePointerLength), Color.White);
        }

        public override void Update(GameTime gameTime, Vector2 mousePosition, Vector2 parentPosition)
        {
            if (GameStats.UIElementEngaged && !IsEngaged) return;

            //Break Engagement
            if (IsEngaged && !Input.IsLMBPressed())
            {
                GameStats.UIElementEngaged = false;
                IsEngaged = false;
            }

            if (!Input.IsLMBPressed()) return;

            Vector2 bound1 = Position + parentPosition + Vector2.One*border;
            Vector2 bound2 = bound1 + Dimensions - Vector2.One*border*2;

            float xcoord = (mousePosition.X - bound1.X)/(bound2.X - bound1.X);
            float ycoord = (mousePosition.Y - bound1.Y )/ (bound2.Y - bound1.Y);

            if (!IsEngaged)
            {
                if (xcoord >= 0 && xcoord <= 1 && ycoord >= 0 && ycoord <= 1)
                {
                    IsEngaged = true;
                    GameStats.UIElementEngaged = true;
                }
            }

            if(IsEngaged)
            {
                xcoord = MathHelper.Clamp(xcoord, -0.01f, 1);
                ycoord = MathHelper.Clamp(ycoord, -0.01f, 1.01f);

                GameStats.UIWasUsed = true;

                Color? output = null;
                //Get Color!

                if (xcoord >= 0.85f && xcoord <0.99f)
                {

                    float sixth = 1.0f/6;

                    if(ycoord <= 0) { }
                    else if (ycoord <= sixth)
                    {
                        output = Color.Lerp(Color.Red, Color.Violet, ycoord/sixth);
                    }
                    else if (ycoord <= sixth*2)
                    {
                        output = Color.Lerp(Color.Violet, Color.Blue, (ycoord - sixth)/sixth);
                    }
                    else if (ycoord <= sixth*3)
                    {
                        output = Color.Lerp(Color.Blue, Color.Cyan, (ycoord - sixth*2)/sixth);
                    }
                    else if (ycoord <= sixth*4)
                    {
                        output = Color.Lerp(Color.Cyan, Color.Lime, (ycoord - sixth*3)/sixth);
                    }
                    else if (ycoord <= sixth*5)
                    {
                        output = Color.Lerp(Color.Lime, Color.Yellow, (ycoord - sixth*4)/sixth);
                    }
                    else if (ycoord <= 1)
                    {
                        output = Color.Lerp(Color.Yellow, Color.Red, (ycoord - sixth*5)/sixth);
                    }

                    if (output != null)
                    {
                        CurrentFullColor = (Color) output;
                        _mousePointerFull = mousePosition - Position - parentPosition;
                    }
                }
                else
                {
                    xcoord /= 0.75f;
                    ycoord /= 0.75f;

                    if (ycoord <= 1.05f && xcoord <= 1.05f && xcoord >= 0 && ycoord >= 0)
                    {
                        _mouseFineX = xcoord;
                        _mouseFineY = ycoord;

                        output = CurrentFullColor;

                        _mousePointerFine = mousePosition - Position - parentPosition;
                    }
                    //if (ycoord <= 1.05f && ycoord <= 1.05f)
                    //{
                    //    _mouseFineX = xcoord;
                    //    _mouseFineY = ycoord;

                    //    output = CurrentFullColor;

                    //    _mousePointerFine = mousePosition - Position - parentPosition;
                    //}


                }

                if (output == null) return;

                output = Color.Lerp(
                            Color.Lerp(Color.Black, CurrentFullColor, _mouseFineX),
                            Color.Lerp(Color.Black, Color.White, _mouseFineX), _mouseFineY);

                CurrentFineColor = (Color)output;
                _colorString.Clear();
                _colorString.AppendColor(CurrentFineColor);

                if (ToggleObject != null)
                {
                    if (ToggleField != null) ToggleField.SetValue(ToggleObject, CurrentFineColor, BindingFlags.Public, null, null);
                    if (ToggleProperty != null) ToggleProperty.SetValue(ToggleObject, CurrentFineColor);
                }
                else
                {
                    if (ToggleField != null) ToggleField.SetValue(null, CurrentFineColor, BindingFlags.Static | BindingFlags.Public, null, null);
                    if (ToggleProperty != null) ToggleProperty.SetValue(null, CurrentFineColor);
                }


            }
        }
    }
}