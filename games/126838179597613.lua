--[[

ok i see...
so when you want to auto fight..
`workspace.Goals.World#2["#14"].KeeperStatus.Anchor.FootballKeeperPrompt` you will need to tp to it close,
ofc first of all check if you can beat it at `workspace.Goals.World#2["#14"].KeeperStatus.Anchor.BillboardGui.Frame.Power.Power` so if it's like MyPower > HisPower then we can do this!

to be honest.. #14 can be any other goal .. but world can be different too..

MyPower = game:GetService("Players").LocalPlayer.leaderstats.Kicks (206977186600) <- NumberValue

So if you see if you can beat it, tp to him, press letter `E`, and whenever 
`game:GetService("Players").LocalPlayer.PlayerGui.Goal` is active you will start clicking 20 cps at middle of the `game:GetService("Players").LocalPlayer.PlayerGui.Goal.Click`  x,y pos. 

--]]

-- What works:
-- Auto Train
-- Teleports
-- Auto Open Eggs
-- Auto Get Money

-- Dosent work:
-- Auto Rebirth
-- Auto Fight

-- Auto Rebirth info:
--[[

Rebirth (Frame)
  Visible: true
  ClipsDescendants: false
  BorderColor3: 0.105882, 0.164706, 0.207843
  Style: Enum.FrameStyle.Custom
  LayoutOrder: 0
  BackgroundColor3: 0, 0, 0
  Position: {0.5, 0}, {0.5, 0}
  Name: Rebirth
  ClassName: Frame
  BackgroundTransparency: 0.44999998807907104
  ZIndex: 1
  BorderSizePixel: 0
  Size: {0.489406794, 0}, {0.5, 0}
    RebirthFrame (Frame)
      Visible: true
      ClipsDescendants: false
      BorderColor3: 0, 0, 0
      Style: Enum.FrameStyle.Custom
      LayoutOrder: 0
      BackgroundColor3: 0.192157, 0.192157, 0.192157
      Position: {0.5, 0}, {0.571236014, 0}
      Name: RebirthFrame
      ClassName: Frame
      BackgroundTransparency: 1
      ZIndex: 1
      BorderSizePixel: 0
      Size: {1, 0}, {0.839797735, 0}
        Cost (Frame)
          Visible: true
          ClipsDescendants: false
          BorderColor3: 0.105882, 0.164706, 0.207843
          Style: Enum.FrameStyle.Custom
          LayoutOrder: 0
          BackgroundColor3: 0, 0, 0
          Position: {0.5, 0}, {0.699999988, 0}
          Name: Cost
          ClassName: Frame
          BackgroundTransparency: 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.75999999, 0}, {0.109359667, 0}
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            YouNeed (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 2
              BorderSizePixel: 0
              Size: {0.923076928, 0}, {0.731680155, 0}
              Name: YouNeed
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 0, 0
              BorderColor3: 0, 0, 0
              Text: Rebirth resets: Levels & Kicks
              Position: {0.49999994, 0}, {-0.56445694, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
            Background (Frame)
              Visible: true
              ClipsDescendants: false
              BorderColor3: 0.105882, 0.164706, 0.207843
              Style: Enum.FrameStyle.Custom
              LayoutOrder: 0
              BackgroundColor3: 1, 1, 1
              Position: {0, 0}, {0, 0}
              Name: Background
              ClassName: Frame
              BackgroundTransparency: 1
              ZIndex: 1
              BorderSizePixel: 0
              Size: {1, 0}, {1, 0}
                ProgressBar (Frame)
                  Visible: true
                  ClipsDescendants: false
                  BorderColor3: 0, 0, 0
                  Style: Enum.FrameStyle.Custom
                  LayoutOrder: 0
                  BackgroundColor3: 1, 1, 1
                  Position: {0, 0}, {0.5, 0}
                  Name: ProgressBar
                  ClassName: Frame
                  BackgroundTransparency: 0
                  ZIndex: 1
                  BorderSizePixel: 0
                  Size: {1, 0}, {1, 0}
                    GoldV2 (UIGradient)
                      Name: GoldV2
                      ClassName: UIGradient
            Amount (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 2
              BorderSizePixel: 0
              Size: {0.584999979, 0}, {0.800000012, 0}
              Name: Amount
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0.105882, 0.164706, 0.207843
              Text: Level: 95/95
              Position: {0.5, 0}, {0.5, 0}
              Visible: true
              TextSize: 17
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
        RebirthButton (TextButton)
          LayoutOrder: 3
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 3
          BorderSizePixel: 0
          Size: {0.349999994, 0}, {0.170000002, 0}
          Name: RebirthButton
          TextXAlignment: Enum.TextXAlignment.Center
          TextStrokeColor3: 0, 0, 0
          TextColor3: 0, 0, 0
          BorderColor3: 0.105882, 0.164706, 0.207843
          Text: 
          Position: {0.300000012, 0}, {0.898843586, 0}
          Visible: true
          TextSize: 14
          Font: Enum.Font.SourceSans
          BackgroundTransparency: 0
          ClassName: TextButton
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 1, 1, 1
            TitleBack (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 4
              BorderSizePixel: 0
              Size: {0.800000012, 0}, {0.765999973, 0}
              Name: TitleBack
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0.105882, 0.164706, 0.207843
              Text: Rebirth
              Position: {0.5, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
            UICorner (UICorner)
              Name: UICorner
              ClassName: UICorner
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            Green (UIGradient)
              Name: Green
              ClassName: UIGradient
        AutoRebirthButton (TextButton)
          LayoutOrder: 0
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 2
          BorderSizePixel: 0
          Size: {0.25, 0}, {0.131425604, 0}
          Name: AutoRebirthButton
          TextXAlignment: Enum.TextXAlignment.Center
          TextStrokeColor3: 0, 0, 0
          TextColor3: 1, 1, 1
          BorderColor3: 0, 0, 0
          Text: 
          Position: {0.99999994, 0}, {1.18830001, 0}
          Visible: false
          TextSize: 14
          Font: Enum.Font.FredokaOne
          BackgroundTransparency: 0
          ClassName: TextButton
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 1, 0, 0
            UIGradient (UIGradient)
              Name: UIGradient
              ClassName: UIGradient
            TextLabel (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 3
              BorderSizePixel: 0
              Size: {0.870293856, 0}, {0.8348912, 0}
              Name: TextLabel
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0, 0, 0
              Text: Auto: OFF
              Position: {0.502748609, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
            UICorner (UICorner)
              Name: UICorner
              ClassName: UICorner
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
        SkipButton (TextButton)
          LayoutOrder: 3
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 3
          BorderSizePixel: 0
          Size: {0.349999994, 0}, {0.170000002, 0}
          Name: SkipButton
          TextXAlignment: Enum.TextXAlignment.Center
          TextStrokeColor3: 0, 0, 0
          TextColor3: 0, 0, 0
          BorderColor3: 0.105882, 0.164706, 0.207843
          Text: 
          Position: {0.709999979, 0}, {0.898843586, 0}
          Visible: true
          TextSize: 14
          Font: Enum.Font.SourceSans
          BackgroundTransparency: 0
          ClassName: TextButton
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 1, 1, 1
            TitleBack (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 4
              BorderSizePixel: 0
              Size: {0.800000012, 0}, {0.765999973, 0}
              Name: TitleBack
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0.105882, 0.164706, 0.207843
              Text: Skip Rebirth
              Position: {0.5, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
            UICorner (UICorner)
              Name: UICorner
              ClassName: UICorner
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            Blue (UIGradient)
              Name: Blue
              ClassName: UIGradient
            TitleBack (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 4
              BorderSizePixel: 0
              Size: {0.589999974, 0}, {0.49000001, 0}
              Name: TitleBack
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0.105882, 0.164706, 0.207843
              Text: KEEP EVERYTHING
              Position: {0.5, 0}, {1, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
                GoldV2 (UIGradient)
                  Name: GoldV2
                  ClassName: UIGradient
        NewPower (Frame)
          Visible: true
          ClipsDescendants: false
          BorderColor3: 0.105882, 0.164706, 0.207843
          Style: Enum.FrameStyle.Custom
          LayoutOrder: 0
          BackgroundColor3: 1, 1, 1
          Position: {0.765999973, 0}, {0.219999999, 0}
          Name: NewPower
          ClassName: Frame
          BackgroundTransparency: 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.355000019, 0}, {0.153999999, 0}
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            Red (UIGradient)
              Name: Red
              ClassName: UIGradient
            ImageLabel (ImageLabel)
              LayoutOrder: 0
              ImageTransparency: 0
              Image: rbxassetid://72856756441554
              ImageRectSize: 0, 0
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.330000013, 0}, {0.330000013, 0}
              ClipsDescendants: false
              BorderColor3: 0, 0, 0
              Visible: true
              ImageRectOffset: 0, 0
              BackgroundTransparency: 1
              ClassName: ImageLabel
              ImageColor3: 1, 1, 1
              Position: {0.5, 0}, {0.5, 0}
              Name: ImageLabel
              BackgroundColor3: 1, 1, 1
            TextLabel (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.899999976, 0}, {0.899999976, 0}
              Name: TextLabel
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0, 0, 0
              Text: Kick x10
              Position: {0.5, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
        OldPower (Frame)
          Visible: true
          ClipsDescendants: false
          BorderColor3: 0.105882, 0.164706, 0.207843
          Style: Enum.FrameStyle.Custom
          LayoutOrder: 0
          BackgroundColor3: 1, 1, 1
          Position: {0.266000003, 0}, {0.219999999, 0}
          Name: OldPower
          ClassName: Frame
          BackgroundTransparency: 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.355000019, 0}, {0.153999999, 0}
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            Arrow (ImageLabel)
              LayoutOrder: 0
              ImageTransparency: 0
              Image: rbxassetid://14996495341
              ImageRectSize: 0, 0
              ZIndex: 25
              BorderSizePixel: 0
              Size: {0.199371859, 0}, {0.774591506, 0}
              ClipsDescendants: false
              BorderColor3: 0.105882, 0.164706, 0.207843
              Visible: true
              ImageRectOffset: 0, 0
              BackgroundTransparency: 1
              ClassName: ImageLabel
              ImageColor3: 1, 1, 1
              Position: {1.16400003, 0}, {0.5, 0}
              Name: Arrow
              BackgroundColor3: 1, 1, 1
                UIAspectRatioConstraint (UIAspectRatioConstraint)
                  Name: UIAspectRatioConstraint
                  ClassName: UIAspectRatioConstraint
            Red (UIGradient)
              Name: Red
              ClassName: UIGradient
            ImageLabel (ImageLabel)
              LayoutOrder: 0
              ImageTransparency: 0
              Image: rbxassetid://72856756441554
              ImageRectSize: 0, 0
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.330000013, 0}, {0.330000013, 0}
              ClipsDescendants: false
              BorderColor3: 0, 0, 0
              Visible: true
              ImageRectOffset: 0, 0
              BackgroundTransparency: 1
              ClassName: ImageLabel
              ImageColor3: 1, 1, 1
              Position: {0.5, 0}, {0.5, 0}
              Name: ImageLabel
              BackgroundColor3: 1, 1, 1
            TextLabel (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.899999976, 0}, {0.899999976, 0}
              Name: TextLabel
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0, 0, 0
              Text: Kick x9
              Position: {0.5, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
        NewLevel (Frame)
          Visible: true
          ClipsDescendants: false
          BorderColor3: 0.105882, 0.164706, 0.207843
          Style: Enum.FrameStyle.Custom
          LayoutOrder: 0
          BackgroundColor3: 1, 1, 1
          Position: {0.765999973, 0}, {0.430000007, 0}
          Name: NewLevel
          ClassName: Frame
          BackgroundTransparency: 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.355000019, 0}, {0.153999999, 0}
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            Green (UIGradient)
              Name: Green
              ClassName: UIGradient
            ImageLabel (ImageLabel)
              LayoutOrder: 0
              ImageTransparency: 0
              Image: rbxassetid://83384311884533
              ImageRectSize: 0, 0
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.330000013, 0}, {0.330000013, 0}
              ClipsDescendants: false
              BorderColor3: 0, 0, 0
              Visible: true
              ImageRectOffset: 0, 0
              BackgroundTransparency: 1
              ClassName: ImageLabel
              ImageColor3: 1, 1, 1
              Position: {0.5, 0}, {0.5, 0}
              Name: ImageLabel
              BackgroundColor3: 1, 1, 1
            TextLabel (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.899999976, 0}, {0.899999976, 0}
              Name: TextLabel
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0, 0, 0
              Text: Level 105
              Position: {0.5, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
        OldLevel (Frame)
          Visible: true
          ClipsDescendants: false
          BorderColor3: 0.105882, 0.164706, 0.207843
          Style: Enum.FrameStyle.Custom
          LayoutOrder: 0
          BackgroundColor3: 1, 1, 1
          Position: {0.266000003, 0}, {0.430000007, 0}
          Name: OldLevel
          ClassName: Frame
          BackgroundTransparency: 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.355000019, 0}, {0.153999999, 0}
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            Arrow (ImageLabel)
              LayoutOrder: 0
              ImageTransparency: 0
              Image: rbxassetid://14996495341
              ImageRectSize: 0, 0
              ZIndex: 25
              BorderSizePixel: 0
              Size: {0.199371859, 0}, {0.774591506, 0}
              ClipsDescendants: false
              BorderColor3: 0.105882, 0.164706, 0.207843
              Visible: true
              ImageRectOffset: 0, 0
              BackgroundTransparency: 1
              ClassName: ImageLabel
              ImageColor3: 1, 1, 1
              Position: {1.16400003, 0}, {0.5, 0}
              Name: Arrow
              BackgroundColor3: 1, 1, 1
                UIAspectRatioConstraint (UIAspectRatioConstraint)
                  Name: UIAspectRatioConstraint
                  ClassName: UIAspectRatioConstraint
            Green (UIGradient)
              Name: Green
              ClassName: UIGradient
            ImageLabel (ImageLabel)
              LayoutOrder: 0
              ImageTransparency: 0
              Image: rbxassetid://83384311884533
              ImageRectSize: 0, 0
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.330000013, 0}, {0.330000013, 0}
              ClipsDescendants: false
              BorderColor3: 0, 0, 0
              Visible: true
              ImageRectOffset: 0, 0
              BackgroundTransparency: 1
              ClassName: ImageLabel
              ImageColor3: 1, 1, 1
              Position: {0.5, 0}, {0.5, 0}
              Name: ImageLabel
              BackgroundColor3: 1, 1, 1
            TextLabel (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 1
              BorderSizePixel: 0
              Size: {0.899999976, 0}, {0.899999976, 0}
              Name: TextLabel
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0, 0, 0
              Text: Level 95
              Position: {0.5, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
        After (TextLabel)
          LayoutOrder: 0
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.355000019, 0}, {0.0799999982, 0}
          Name: After
          TextXAlignment: Enum.TextXAlignment.Center
          TextStrokeColor3: 0, 0, 0
          TextColor3: 1, 1, 1
          BorderColor3: 0.105882, 0.164706, 0.207843
          Text: After: 10
          Position: {0.769999981, 0}, {0.0599999987, 0}
          Visible: true
          TextSize: 8
          Font: Enum.Font.Unknown
          BackgroundTransparency: 1
          ClassName: TextLabel
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 1, 1, 1
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
        Before (TextLabel)
          LayoutOrder: 0
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.355000019, 0}, {0.0799999982, 0}
          Name: Before
          TextXAlignment: Enum.TextXAlignment.Center
          TextStrokeColor3: 0, 0, 0
          TextColor3: 1, 1, 1
          BorderColor3: 0.105882, 0.164706, 0.207843
          Text: Before: 9
          Position: {0.266000003, 0}, {0.0599999987, 0}
          Visible: true
          TextSize: 8
          Font: Enum.Font.Unknown
          BackgroundTransparency: 1
          ClassName: TextLabel
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 1, 1, 1
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
        BuyAutoRebirthButton (TextButton)
          LayoutOrder: 0
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 2
          BorderSizePixel: 0
          Size: {0.25, 0}, {0.131425604, 0}
          Name: BuyAutoRebirthButton
          TextXAlignment: Enum.TextXAlignment.Center
          TextStrokeColor3: 0, 0, 0
          TextColor3: 1, 1, 1
          BorderColor3: 0, 0, 0
          Text: 
          Position: {0.99999994, 0}, {1.18830001, 0}
          Visible: true
          TextSize: 14
          Font: Enum.Font.FredokaOne
          BackgroundTransparency: 0
          ClassName: TextButton
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 1, 1, 1
            TextLabel (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 3
              BorderSizePixel: 0
              Size: {0.870293856, 0}, {0.8348912, 0}
              Name: TextLabel
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0, 0, 0
              Text: Auto Rebirth
              Position: {0.502748609, 0}, {0.5, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
            UICorner (UICorner)
              Name: UICorner
              ClassName: UICorner
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            Green (UIGradient)
              Name: Green
              ClassName: UIGradient
            Price (TextLabel)
              LayoutOrder: 0
              TextTransparency: 0
              TextStrokeTransparency: 1
              ZIndex: 4
              BorderSizePixel: 0
              Size: {0.589999974, 0}, {0.49000001, 0}
              Name: Price
              TextXAlignment: Enum.TextXAlignment.Center
              TextStrokeColor3: 0, 0, 0
              TextColor3: 1, 1, 1
              BorderColor3: 0.105882, 0.164706, 0.207843
              Text:  99
              Position: {0.5, 0}, {1, 0}
              Visible: true
              TextSize: 14
              Font: Enum.Font.Unknown
              BackgroundTransparency: 1
              ClassName: TextLabel
              ClipsDescendants: false
              TextYAlignment: Enum.TextYAlignment.Center
              TextScaled: true
              BackgroundColor3: 1, 1, 1
                UIStroke (UIStroke)
                  Name: UIStroke
                  ClassName: UIStroke
                GoldV2 (UIGradient)
                  Name: GoldV2
                  ClassName: UIGradient
    UIAspectRatioConstraint (UIAspectRatioConstraint)
      Name: UIAspectRatioConstraint
      ClassName: UIAspectRatioConstraint
    Header (Frame)
      Visible: true
      ClipsDescendants: false
      BorderColor3: 0, 0, 0
      Style: Enum.FrameStyle.Custom
      LayoutOrder: 0
      BackgroundColor3: 1, 1, 1
      Position: {0.500463426, 0}, {0.070545584, 0}
      Name: Header
      ClassName: Frame
      BackgroundTransparency: 0
      ZIndex: 1
      BorderSizePixel: 0
      Size: {0.999382257, 0}, {0.141090661, 0}
        ImageLabel (ImageLabel)
          LayoutOrder: 0
          ImageTransparency: 0
          Image: rbxassetid://140366643102022
          ImageRectSize: 0, 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.899999976, 0}, {0.899999976, 0}
          ClipsDescendants: false
          BorderColor3: 0, 0, 0
          Visible: true
          ImageRectOffset: 0, 0
          BackgroundTransparency: 1
          ClassName: ImageLabel
          ImageColor3: 1, 1, 1
          Position: {0.0615384616, 0}, {0.5, 0}
          Name: ImageLabel
          BackgroundColor3: 1, 1, 1
            UIAspectRatioConstraint (UIAspectRatioConstraint)
              Name: UIAspectRatioConstraint
              ClassName: UIAspectRatioConstraint
        TextLabel (TextLabel)
          LayoutOrder: 0
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 1
          BorderSizePixel: 0
          Size: {0.44907406, 0}, {0.720000029, 0}
          Name: TextLabel
          TextXAlignment: Enum.TextXAlignment.Left
          TextStrokeColor3: 0, 0, 0
          TextColor3: 1, 1, 1
          BorderColor3: 0, 0, 0
          Text: Rebirth
          Position: {0.353846163, 0}, {0.4799999, 0}
          Visible: true
          TextSize: 14
          Font: Enum.Font.GothamBold
          BackgroundTransparency: 1
          ClassName: TextLabel
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 1, 1, 1
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
        UIStroke (UIStroke)
          Name: UIStroke
          ClassName: UIStroke
        StudsImage (ImageLabel)
          LayoutOrder: 0
          ImageTransparency: 0.6000000238418579
          Image: rbxassetid://111494391746905
          ImageRectSize: 0, 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {1, 0}, {1, 0}
          ClipsDescendants: false
          BorderColor3: 0, 0, 0
          Visible: true
          ImageRectOffset: 0, 0
          BackgroundTransparency: 1
          ClassName: ImageLabel
          ImageColor3: 1, 1, 1
          Position: {0.5, 0}, {0.5, 0}
          Name: StudsImage
          BackgroundColor3: 1, 1, 1
        Purple (UIGradient)
          Name: Purple
          ClassName: UIGradient
    StudsImage (ImageLabel)
      LayoutOrder: 0
      ImageTransparency: 0.6000000238418579
      Image: rbxassetid://111494391746905
      ImageRectSize: 0, 0
      ZIndex: -1
      BorderSizePixel: 0
      Size: {1, 0}, {1, 0}
      ClipsDescendants: false
      BorderColor3: 0, 0, 0
      Visible: true
      ImageRectOffset: 0, 0
      BackgroundTransparency: 1
      ClassName: ImageLabel
      ImageColor3: 1, 1, 1
      Position: {0.5, 0}, {0.5, 0}
      Name: StudsImage
      BackgroundColor3: 1, 1, 1
    X (ImageButton)
      LayoutOrder: 0
      ImageTransparency: 0
      Image: 
      ImageRectSize: 0, 0
      ZIndex: 1
      BorderSizePixel: 1
      Size: {0.106622115, 0}, {0.0998278856, 0}
      ClipsDescendants: false
      BorderColor3: 0.105882, 0.164706, 0.207843
      Visible: true
      ImageRectOffset: 0, 0
      BackgroundTransparency: 1
      ClassName: ImageButton
      ImageColor3: 1, 1, 1
      Position: {0.920000017, 0}, {0.0700000003, 0}
      Name: X
      BackgroundColor3: 0.639216, 0.635294, 0.647059
        exitframe (Frame)
          Visible: true
          ClipsDescendants: false
          BorderColor3: 0.105882, 0.164706, 0.207843
          Style: Enum.FrameStyle.Custom
          LayoutOrder: 0
          BackgroundColor3: 1, 1, 1
          Position: {0.0166666675, 0}, {0, 0}
          Name: exitframe
          ClassName: Frame
          BackgroundTransparency: 0
          ZIndex: 1
          BorderSizePixel: 0
          Size: {1, 0}, {1, 0}
            UIGradient (UIGradient)
              Name: UIGradient
              ClassName: UIGradient
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
        close_texture (ImageLabel)
          LayoutOrder: 0
          ImageTransparency: 0
          Image: rbxassetid://94576060028612
          ImageRectSize: 0, 0
          ZIndex: 1
          BorderSizePixel: 1
          Size: {1, 0}, {1, 0}
          ClipsDescendants: false
          BorderColor3: 0.105882, 0.164706, 0.207843
          Visible: true
          ImageRectOffset: 0, 0
          BackgroundTransparency: 1
          ClassName: ImageLabel
          ImageColor3: 1, 1, 1
          Position: {0.0166666675, 0}, {0, 0}
          Name: close_texture
          BackgroundColor3: 0.639216, 0.635294, 0.647059
        RotateImage (TextLabel)
          LayoutOrder: 0
          TextTransparency: 0
          TextStrokeTransparency: 1
          ZIndex: 2
          BorderSizePixel: 1
          Size: {0.699999988, 0}, {0.699999988, 0}
          Name: RotateImage
          TextXAlignment: Enum.TextXAlignment.Center
          TextStrokeColor3: 0, 0, 0
          TextColor3: 0.85098, 0.85098, 0.85098
          BorderColor3: 0.105882, 0.164706, 0.207843
          Text: X
          Position: {0.5, 0}, {0.5, 0}
          Visible: true
          TextSize: 50
          Font: Enum.Font.Cartoon
          BackgroundTransparency: 1
          ClassName: TextLabel
          ClipsDescendants: false
          TextYAlignment: Enum.TextYAlignment.Center
          TextScaled: true
          BackgroundColor3: 0.639216, 0.635294, 0.647059
            UIStroke (UIStroke)
              Name: UIStroke
              ClassName: UIStroke
            UITextSizeConstraint (UITextSizeConstraint)
              Name: UITextSizeConstraint
              ClassName: UITextSizeConstraint
        UIAspectRatioConstraint (UIAspectRatioConstraint)
          Name: UIAspectRatioConstraint
          ClassName: UIAspectRatioConstraint
    UIStroke (UIStroke)
      Name: UIStroke
      ClassName: UIStroke
    UIScale (UIScale)
      Name: UIScale
      ClassName: UIScale

--]]

-- Auto Fight Keeper info:
--[[

Anchor (Part)
  Reflectance: 0
  CanCollide: false
  Color: 0.639216, 0.635294, 0.647059
  CFrame: 0, 9.207057, -208.323639, -1, 0, 0, 0, 1, 0, 0, 0, -1
  Anchored: true
  Transparency: 1
  Name: Anchor
  Position: 0, 9.207056999206543, -208.32363891601562
  Locked: false
  Material: Enum.Material.Plastic
  ClassName: Part
  Size: 2, 2, 2
    BillboardGui (BillboardGui)
      MaxDistance: 80
      Name: BillboardGui
      ClassName: BillboardGui
      StudsOffset: 0, 4.800000190734863, 0
      AlwaysOnTop: false
      Size: {6.4000001, 0}, {6.4000001, 0}
        Frame (Frame)
          Visible: true
          BorderColor3: 0, 0, 0
          Position: {0, 0}, {0, 0}
          Name: Frame
          ClassName: Frame
          BackgroundTransparency: 1
          BackgroundColor3: 1, 1, 1
          BorderSizePixel: 0
          Size: {1, 0}, {1, 0}
            Power (Frame)
              Visible: true
              BorderColor3: 0, 0, 0
              Position: {0, 0}, {0, 0}
              Name: Power
              ClassName: Frame
              BackgroundTransparency: 1
              BackgroundColor3: 1, 1, 1
              BorderSizePixel: 0
              Size: {1, 0}, {0.300000012, 0}
                ImageLabel (ImageLabel)
                  Visible: true
                  ImageTransparency: 0
                  BorderColor3: 0, 0, 0
                  ImageColor3: 1, 1, 1
                  Position: {0, 0}, {0, 0}
                  Image: rbxassetid://72856756441554
                  Name: ImageLabel
                  ClassName: ImageLabel
                  BackgroundTransparency: 1
                  BackgroundColor3: 1, 1, 1
                  BorderSizePixel: 0
                  Size: {0.800000012, 0}, {0.800000012, 0}
                Power (TextLabel)
                  Visible: true
                  TextColor3: 1, 1, 1
                  BorderColor3: 0, 0, 0
                  Text: 25B
                  Position: {0, 0}, {0, 0}
                  TextSize: 24
                  TextScaled: true
                  Font: Enum.Font.Unknown
                  Name: Power
                  ClassName: TextLabel
                  BackgroundTransparency: 1
                  BackgroundColor3: 1, 1, 1
                  BorderSizePixel: 0
                  Size: {0.461538464, 0}, {1, 0}
                    UIStroke (UIStroke)
                      Name: UIStroke
                      ClassName: UIStroke
                UIListLayout (UIListLayout)
                  Name: UIListLayout
                  ClassName: UIListLayout
            Name (Frame)
              Visible: true
              BorderColor3: 0, 0, 0
              Position: {0, 0}, {0, 0}
              Name: Name
              ClassName: Frame
              BackgroundTransparency: 1
              BackgroundColor3: 1, 1, 1
              BorderSizePixel: 0
              Size: {1, 0}, {0.300000012, 0}
                ImageLabel (ImageLabel)
                  Visible: false
                  ImageTransparency: 0
                  BorderColor3: 0, 0, 0
                  ImageColor3: 1, 1, 1
                  Position: {0, 0}, {0, 0}
                  Image: rbxassetid://79129002076576
                  Name: ImageLabel
                  ClassName: ImageLabel
                  BackgroundTransparency: 1
                  BackgroundColor3: 1, 1, 1
                  BorderSizePixel: 0
                  Size: {0.800000012, 0}, {0.800000012, 0}
                UIListLayout (UIListLayout)
                  Name: UIListLayout
                  ClassName: UIListLayout
                TextLabel (TextLabel)
                  Visible: true
                  TextColor3: 1, 1, 1
                  BorderColor3: 0, 0, 0
                  Text: Gold Brick
                  Position: {0, 0}, {0, 0}
                  TextSize: 24
                  TextScaled: true
                  Font: Enum.Font.Unknown
                  Name: TextLabel
                  ClassName: TextLabel
                  BackgroundTransparency: 1
                  BackgroundColor3: 1, 1, 1
                  BorderSizePixel: 0
                  Size: {1, 0}, {1, 0}
                    UIStroke (UIStroke)
                      Name: UIStroke
                      ClassName: UIStroke
            UIListLayout (UIListLayout)
              Name: UIListLayout
              ClassName: UIListLayout
            Status (Frame)
              Visible: true
              BorderColor3: 0, 0, 0
              Position: {0, 0}, {0, 0}
              Name: Status
              ClassName: Frame
              BackgroundTransparency: 1
              BackgroundColor3: 1, 1, 1
              BorderSizePixel: 0
              Size: {1, 0}, {0.300000012, 0}
                Unlocked (ImageLabel)
                  Visible: false
                  ImageTransparency: 0
                  BorderColor3: 0, 0, 0
                  ImageColor3: 1, 1, 1
                  Position: {0.5, 0}, {0.5, 0}
                  Image: rbxassetid://130276845607118
                  Name: Unlocked
                  ClassName: ImageLabel
                  BackgroundTransparency: 1
                  BackgroundColor3: 1, 1, 1
                  BorderSizePixel: 0
                  Size: {0.800000012, 0}, {0.800000012, 0}
                Locked (ImageLabel)
                  Visible: true
                  ImageTransparency: 0
                  BorderColor3: 0, 0, 0
                  ImageColor3: 1, 1, 1
                  Position: {0.5, 0}, {0.5, 0}
                  Image: rbxassetid://100973902594575
                  Name: Locked
                  ClassName: ImageLabel
                  BackgroundTransparency: 1
                  BackgroundColor3: 1, 1, 1
                  BorderSizePixel: 0
                  Size: {0.800000012, 0}, {0.800000012, 0}
    FootballKeeperPrompt (ProximityPrompt)
      Name: FootballKeeperPrompt
      ClassName: ProximityPrompt

--]]

return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local LocalPlayer = Players.LocalPlayer

    -- Dynamic layout loading guard to block fake executor clicks during UI construction
    local uiLoaded = false
    task.delay(1.2, function()
        uiLoaded = true
    end)

    -- Real-time Logging Helper (Viewable via F9 Console)
    local function log(module, msg)
        print(string.format("[TaperUI - %s] %s", module, msg))
    end

    -- Localized State Configuration for Win Farm
    local winFarmActive = false
    local loopInterval = 0.5
    local selectedWorld = "World1"
    local selectedGate = "4"
    local lastLockWarning = 0

    -- Localized State Configuration for Auto Rebirth
    local autoRebirthActive = false

    -- Localized State Configuration for Auto Fight Keeper
    local autoFightActive = false

    -- Tracks selected gates individually per world
    local selectedGates = {
        World1 = "4",
        World2 = "11",
        World3 = "21",
        World4 = "31"
    }

    -- Build separated static lists for the gates
    local gatesW1 = {}
    for i = 1, 10 do table.insert(gatesW1, tostring(i)) end

    local gatesW2 = {}
    for i = 11, 20 do table.insert(gatesW2, tostring(i)) end

    local gatesW3 = {}
    for i = 21, 30 do table.insert(gatesW3, tostring(i)) end

    local gatesW4 = {}
    for i = 31, 40 do table.insert(gatesW4, tostring(i)) end

    local worlds = {"World1", "World2", "World3", "World4"}

    -- Localized State Configuration for AFK Training
    local autoTrainActive = false
    local selectedTrainingSpot = "World 1 - 1x (0 Rebirth)"
    local lastTrainWarning = 0
    
    local trainingSpots = {
        ["World 1 - 1x (0 Rebirth)"] = {pos = Vector3.new(791, 9, 635), req = 0},
        ["World 1 - 1.5x (1 Rebirth)"] = {pos = Vector3.new(791, 9, 608), req = 1},
        ["World 1 - 2x (3 Rebirth)"] = {pos = Vector3.new(791, 9, 578), req = 3},
        ["World 1 - 3x (5 Rebirth)"] = {pos = Vector3.new(790, 9, 549), req = 5},
        
        ["World 2 - 4x (2 Rebirth)"] = {pos = Vector3.new(-53, 9, 34), req = 2},
        ["World 2 - 6x (3 Rebirth)"] = {pos = Vector3.new(-53, 9, 7), req = 3},
        ["World 2 - 10x (5 Rebirth)"] = {pos = Vector3.new(-53, 9, -23), req = 5},
        ["World 2 - 15x (10 Rebirth)"] = {pos = Vector3.new(-53, 9, -50), req = 10},
        
        ["World 3 - 5x (4 Rebirth)"] = {pos = Vector3.new(-764, 9, 754), req = 4},
        ["World 3 - 8x (7 Rebirth)"] = {pos = Vector3.new(-764, 9, 726), req = 7},
        ["World 3 - 12x (10 Rebirth)"] = {pos = Vector3.new(-764, 9, 697), req = 10},
        ["World 3 - 15x (12 Rebirth)"] = {pos = Vector3.new(-764, 9, 670), req = 12},
        
        ["World 4 - 8x (6 Rebirth)"] = {pos = Vector3.new(-868, 9, 34), req = 6},
        ["World 4 - 12x (10 Rebirth)"] = {pos = Vector3.new(-868, 9, 7), req = 10},
        ["World 4 - 18x (15 Rebirth)"] = {pos = Vector3.new(-868, 9, -23), req = 15},
        ["World 4 - 25x (20 Rebirth)"] = {pos = Vector3.new(-868, 9, -50), req = 20}
    }

    local trainingChoices = {
        "World 1 - 1x (0 Rebirth)",
        "World 1 - 1.5x (1 Rebirth)",
        "World 1 - 2x (3 Rebirth)",
        "World 1 - 3x (5 Rebirth)",
        "World 2 - 4x (2 Rebirth)",
        "World 2 - 6x (3 Rebirth)",
        "World 2 - 10x (5 Rebirth)",
        "World 2 - 15x (10 Rebirth)",
        "World 3 - 5x (4 Rebirth)",
        "World 3 - 8x (7 Rebirth)",
        "World 3 - 12x (10 Rebirth)",
        "World 3 - 15x (12 Rebirth)",
        "World 4 - 8x (6 Rebirth)",
        "World 4 - 12x (10 Rebirth)",
        "World 4 - 18x (15 Rebirth)",
        "World 4 - 25x (20 Rebirth)"
    }

    -- Localized State Configuration for Hatching
    local autoHatchActive = false
    local hatchInterval = 1.0
    local selectedEggCombo = "World1 - Egg1"
    local selectedHatchKey = Enum.KeyCode.E
    local hasPressedT = false
    local lastAffordWarning = 0

    -- Static mappings for targetable Eggs
    local eggChoices = {
        "World1 - Egg1", "World1 - Egg2",
        "World2 - Egg3", "World2 - Egg4",
        "World3 - Egg5", "World3 - Egg6",
        "World4 - Egg7", "World4 - Egg8"
    }

    -- Helper: Safely reads the client's rebirth count from leaderstats
    local function getRebirthCount()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local rebirthVal = leaderstats:FindFirstChild("Rebirth")
            if rebirthVal then
                return tonumber(rebirthVal.Value) or 0
            end
        end
        return 0
    end

    -- Suffix multipliers to evaluate simulator values
    local suffixMultiplier = {
        K = 1e3,
        M = 1e6,
        B = 1e9,
        T = 1e12,
        QA = 1e15,
        QD = 1e15,
        QI = 1e18,
        QT = 1e18,
        SX = 1e21,
        SP = 1e24,
        OC = 1e27,
        NO = 1e30,
        NN = 1e30,
        DC = 1e33
    }

    -- Helper: Parses abbreviated formatted numbers into raw numerical values anywhere in a string
    local function parseAbbreviatedNumber(str)
        if not str then return 0 end
        str = str:gsub(",", "")
        local numPart, suffixPart = str:match("([%d%.]+)%s*([%a]*)")
        if not numPart then return 0 end
        
        local num = tonumber(numPart) or 0
        if suffixPart and suffixPart ~= "" then
            local suffix = suffixPart:upper()
            local multiplier = suffixMultiplier[suffix]
            if multiplier then
                return num * multiplier
            end
        end
        return num
    end

    -- Helper: Formats numbers back into standard abbreviations for debug logging
    local function formatBigNumber(val)
        if not val then return "0" end
        if val >= 1e33 then return string.format("%.2fDC", val / 1e33)
        elseif val >= 1e30 then return string.format("%.2fNO", val / 1e30)
        elseif val >= 1e27 then return string.format("%.2fOC", val / 1e27)
        elseif val >= 1e24 then return string.format("%.2fSP", val / 1e24)
        elseif val >= 1e21 then return string.format("%.2fSX", val / 1e21)
        elseif val >= 1e18 then return string.format("%.2fQI", val / 1e18)
        elseif val >= 1e15 then return string.format("%.2fQD", val / 1e15)
        elseif val >= 1e12 then return string.format("%.2fT", val / 1e12)
        elseif val >= 1e9 then return string.format("%.2fB", val / 1e9)
        elseif val >= 1e6 then return string.format("%.2fM", val / 1e6)
        elseif val >= 1e3 then return string.format("%.2fK", val / 1e3)
        end
        return string.format("%.2f", val)
    end

    -- Helper: Resolves actual world folder in workspace.Goals (handles optional '#' prefix dynamically)
    local function resolveWorldFolder(worldName)
        if not workspace:FindFirstChild("Goals") then return nil end
        local cleanName = worldName:gsub("#", ""):gsub("%s", "")
        local num = cleanName:match("%d+")
        if num then
            return workspace.Goals:FindFirstChild("World" .. num) or workspace.Goals:FindFirstChild("World#" .. num) or workspace.Goals:FindFirstChild("World #" .. num)
        end
        return workspace.Goals:FindFirstChild(worldName)
    end

    -- Helper: Resolves actual gate folder inside the active world folder (handles optional '#' prefix dynamically)
    local function resolveGateFolder(worldFolder, gateName)
        if not worldFolder then return nil end
        local cleanGate = gateName:gsub("#", ""):gsub("%s", "")
        return worldFolder:FindFirstChild("#" .. cleanGate) or worldFolder:FindFirstChild(" #" .. cleanGate) or worldFolder:FindFirstChild(cleanGate)
    end

    -- Helper: Dynamically determines the active physical world based on player distance to active gates
    local function getActiveWorld()
        if autoFightActive or winFarmActive then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local closestWorld = nil
                local closestDist = math.huge
                
                for _, wName in ipairs({"World1", "World2", "World3", "World4"}) do
                    local folder = resolveWorldFolder(wName)
                    if folder then
                        -- Measure distance to any gate inside this world folder
                        for _, gateFolder in ipairs(folder:GetChildren()) do
                            local keeperStatus = gateFolder:FindFirstChild("KeeperStatus")
                            local anchor = keeperStatus and keeperStatus:FindFirstChild("Anchor")
                            if anchor and anchor:IsA("BasePart") then
                                local dist = (root.Position - anchor.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closestWorld = wName
                                end
                                break -- Distance check completed for this world structure
                            end
                        end
                    end
                end
                
                if closestWorld then
                    return closestWorld
                end
            end
        end
        return selectedWorld
    end

    -- Helper: Safely reads the client's current Wins balance from leaderstats
    local function getWinsCount()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local winsVal = leaderstats:FindFirstChild("Wins") or leaderstats:FindFirstChild("Win")
            if winsVal then
                if winsVal:IsA("StringValue") then
                    return parseAbbreviatedNumber(winsVal.Value)
                else
                    return tonumber(winsVal.Value) or 0
                end
            end
        end
        return 0
    end

    -- Helper: Checks whether the player's balance allows the targeted hatch purchase
    local function canAffordEgg()
        local eggWorld, eggName = selectedEggCombo:match("^(World%d+)%s*-%s*(Egg%d+)$")
        if not eggWorld or not eggName then return true, 0, 0 end

        local costParsed = nil
        local success = pcall(function()
            local eggsFolder = workspace:FindFirstChild("Eggs")
            if not eggsFolder then return end
            local worldFolder = eggsFolder:FindFirstChild(eggWorld)
            if not worldFolder then return end
            local eggFolder = worldFolder:FindFirstChild(eggName)
            if not eggFolder then return end
            
            local primary = eggFolder:FindFirstChild("PetSystemEggModel") and eggFolder.PetSystemEggModel:FindFirstChild("Primary")
            if not primary then return end
            
            local priceTemplate = primary:FindFirstChild("Template_Egg_Price")
            if not priceTemplate then return end
            
            local frame = priceTemplate:FindFirstChild("Frame")
            if not frame then return end
            
            local textLabel = frame:FindFirstChild("TextLabel")
            if textLabel and textLabel:IsA("TextLabel") then
                costParsed = parseAbbreviatedNumber(textLabel.Text)
            end
        end)

        -- If path failed to resolve, proceed to prevent blocking the hatch loop on game structural changes
        if not success or costParsed == nil then
            return true, 0, 0
        end

        local currentWins = getWinsCount()
        return currentWins >= costParsed, costParsed, currentWins
    end

    -- Helper: Returns the upgraded hatch limit count dynamically from PlayerGui
    local function getUpgradedHatchAmount()
        local amount = 2 -- Fallback default is 2
        pcall(function()
            local upgradesFrame = LocalPlayer.PlayerGui.MainUI.Frames.Upgrades.UpgradesFrame
            local scrollingFrame = upgradesFrame:FindFirstChild("ScrollingFrame")
            if scrollingFrame then
                local targetLabel = nil
                local template = scrollingFrame:FindFirstChild("Template")
                if template then
                    local stats = template:FindFirstChild("Stats")
                    targetLabel = stats and stats:FindFirstChild("current")
                end
                
                -- Fallback lookup if templates are renamed dynamically
                if not targetLabel or not targetLabel:IsA("TextLabel") then
                    for _, child in ipairs(scrollingFrame:GetChildren()) do
                        local stats = child:FindFirstChild("Stats")
                        local current = stats and stats:FindFirstChild("current")
                        if current and current:IsA("TextLabel") then
                            local text = current.Text
                            if text:find("-") or text:find("%%") then
                                targetLabel = current
                                break
                            end
                        end
                    end
                end

                if targetLabel and targetLabel:IsA("TextLabel") then
                    local cleanText = targetLabel.Text:gsub("%-", ""):gsub("%%", "")
                    local parsedVal = tonumber(cleanText)
                    if parsedVal and parsedVal > 2 then
                        amount = parsedVal
                    end
                end
            end
        end)
        return amount
    end

    -- Helper: Evaluates the client's screen layout and physically triggers a mouse-click sequence
    local function clickButtonOnScreen(btn)
        if not btn then return end
        pcall(function()
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local clickX = absPos.X + (absSize.X / 2)
            local clickY = absPos.Y + (absSize.Y / 2)
            if VirtualInputManager then
                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
            end
        end)
    end

    -- Helper: Attempts to open the Rebirth UI if it is currently closed/unpopulated
    local function forceOpenRebirthUI()
        pcall(function()
            local rebirth = LocalPlayer.PlayerGui:FindFirstChild("Rebirth", true)
            if rebirth and not rebirth.Visible then
                -- Click screen button to activate frame state
                for _, desc in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                        local name = desc.Name:lower()
                        local text = desc:IsA("TextButton") and desc.Text:lower() or ""
                        if name:find("rebirth") or text:find("rebirth") then
                            if typeof(firesignal) == "function" then
                                firesignal(desc.MouseButton1Click)
                                firesignal(desc.Activated)
                            end
                            break
                        end
                    end
                end
                task.wait(0.1)
                rebirth.Visible = true
            end
        end)
    end

    -- Helper: Parses active Level progress and safely triggers the rebirth button signals
    local function checkAndExecuteRebirth()
        local success, err = pcall(function()
            -- Force-open the UI frame to update the cost text label
            forceOpenRebirthUI()

            local rebirth = LocalPlayer.PlayerGui:FindFirstChild("Rebirth", true)
            if not rebirth then
                log("Rebirth", "Rebirth GUI container not found in PlayerGui.")
                return
            end

            local rebirthFrame = rebirth:FindFirstChild("RebirthFrame")
            if not rebirthFrame then
                log("Rebirth", "RebirthFrame missing inside Rebirth container.")
                return
            end

            local amountLabel = rebirthFrame:FindFirstChild("Cost") and rebirthFrame.Cost:FindFirstChild("Amount")
            local rebirthButton = rebirthFrame:FindFirstChild("RebirthButton")

            if not amountLabel then
                log("Rebirth", "Cost.Amount TextLabel is missing.")
                return
            end
            if not rebirthButton then
                log("Rebirth", "RebirthButton TextButton is missing.")
                return
            end

            local text = amountLabel.Text -- expected format: "Level: 95/95"
            log("Rebirth", "Read Rebirth Label Text: " .. tostring(text))

            local currentStr, requiredStr = text:match("(%d+)%s*/%s*(%d+)")
            if currentStr and requiredStr then
                local currentLevel = tonumber(currentStr)
                local requiredLevel = tonumber(requiredStr)
                
                log("Rebirth", string.format("Levels parsed successfully: %d/%d", currentLevel, requiredLevel))
                
                if currentLevel and requiredLevel and currentLevel >= requiredLevel then
                    log("Rebirth", "Requirements met! Processing rebirth trigger sequence...")

                    -- 1. Attempt Silent Network Rebirth via Remote Event / Remote Function
                    local replicatedStorage = game:GetService("ReplicatedStorage")
                    for _, desc in ipairs(replicatedStorage:GetDescendants()) do
                        if desc:IsA("RemoteEvent") and (desc.Name:lower():find("rebirth") or desc.Name:lower() == "r") then
                            desc:FireServer()
                        elseif desc:IsA("RemoteFunction") and (desc.Name:lower():find("rebirth") or desc.Name:lower() == "r") then
                            desc:InvokeServer()
                        end
                    end

                    -- 2. Trigger UI click sequence via mouse-interaction signals
                    if typeof(firesignal) == "function" then
                        firesignal(rebirthButton.MouseButton1Click)
                        firesignal(rebirthButton.MouseButton1Down)
                        firesignal(rebirthButton.MouseButton1Up)
                        firesignal(rebirthButton.Activated)
                    end

                    -- 3. Physically click the button on-screen to bypass anti-cheat listeners
                    clickButtonOnScreen(rebirthButton)

                    -- 4. Clear any confirmation alerts that appear subsequently
                    task.delay(0.15, function()
                        for _, desc in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                            if desc:IsA("TextButton") and desc.Visible then
                                local btnText = desc.Text:lower()
                                local titleBack = desc:FindFirstChild("TitleBack")
                                local titleText = titleBack and titleBack:IsA("TextLabel") and titleBack.Text:lower() or ""
                                
                                if btnText == "yes" or btnText == "confirm" or btnText:find("rebirth") or titleText:find("yes") or titleText:find("confirm") then
                                    firesignal(desc.MouseButton1Click)
                                    firesignal(desc.Activated)
                                    clickButtonOnScreen(desc)
                                end
                            end
                        end
                    end)
                end
            else
                log("Rebirth", "Failed to parse current/required levels from amount label.")
            end
        end)

        if not success then
            log("Rebirth", "Error executing check: " .. tostring(err))
        end
    end

    -- Helper: Verifies unlock status of specific goal markers dynamically
    local function isSpecificGateUnlocked(worldName, gateName)
        local success, result = pcall(function()
            local goalFolder = resolveWorldFolder(worldName)
            if not goalFolder then 
                -- If previous world is streamed out, assume unlocked as we have transitioned beyond it
                return worldName ~= getActiveWorld()
            end
            
            local gateFolder = resolveGateFolder(goalFolder, gateName)
            if not gateFolder then 
                return worldName ~= getActiveWorld()
            end
            
            local keeperStatus = gateFolder:FindFirstChild("KeeperStatus")
            if not keeperStatus then 
                return true
            end

            local status = keeperStatus.Anchor.BillboardGui.Frame.Status
            local unlocked = status:FindFirstChild("Unlocked")

            if unlocked then
                if unlocked:IsA("BoolValue") then
                    return unlocked.Value
                elseif unlocked:IsA("StringValue") then
                    return unlocked.Value:lower() == "unlocked" or unlocked.Value == "true"
                elseif unlocked:IsA("GuiObject") then
                    return unlocked.Visible
                end
                return true
            end

            if status:IsA("TextLabel") then
                return status.Text:lower():find("unlocked") ~= nil
            end

            return false
        end)
        
        if not success then
            return worldName ~= getActiveWorld() -- Fallback to locked on active world error
        end
        return result
    end

    -- Helper: Dynamically determines the next locked gate to challenge inside the selected world
    local function getCurrentTargetGate()
        local activeWorld = getActiveWorld()
        local gatesList = {}
        if activeWorld == "World1" then
            gatesList = gatesW1
        elseif activeWorld == "World2" then
            gatesList = gatesW2
        elseif activeWorld == "World3" then
            gatesList = gatesW3
        elseif activeWorld == "World4" then
            gatesList = gatesW4
        end
        
        for _, gate in ipairs(gatesList) do
            if not isSpecificGateUnlocked(activeWorld, gate) then
                return gate
            end
        end
        
        -- Fallback to currently selected gate if all are unlocked
        return gatesList[#gatesList] or selectedGate
    end

    -- Helper: Checks if player's kicks balance exceeds target Keeper's power
    local function checkCanBeatKeeper(gate)
        local activeWorld = getActiveWorld()
        local success, result = pcall(function()
            local goalFolder = resolveWorldFolder(activeWorld)
            if not goalFolder then return false end
            local gateFolder = resolveGateFolder(goalFolder, gate)
            if not gateFolder then return false end
            local keeperStatus = gateFolder:FindFirstChild("KeeperStatus")
            if not keeperStatus then return false end
            
            local anchor = keeperStatus:FindFirstChild("Anchor")
            if not anchor then return false end
            
            local billboard = anchor:FindFirstChildOfClass("BillboardGui")
            local frame = billboard and billboard:FindFirstChild("Frame")
            local powerFolder = frame and frame:FindFirstChild("Power")
            local powerLabel = powerFolder and (powerFolder:FindFirstChild("Power") or powerFolder)
            
            if powerLabel and powerLabel:IsA("TextLabel") then
                local keeperPower = parseAbbreviatedNumber(powerLabel.Text)
                local myPowerVal = LocalPlayer.leaderstats:FindFirstChild("Kicks")
                local myPower = 0
                if myPowerVal then
                    if myPowerVal:IsA("StringValue") then
                        myPower = parseAbbreviatedNumber(myPowerVal.Value)
                    else
                        myPower = tonumber(myPowerVal.Value) or 0
                    end
                end
                
                local affordable = myPower > keeperPower
                log("Fight", string.format("Target: %s | Keeper Power: %s | My Kicks: %s | Can Beat: %s", gate, formatBigNumber(keeperPower), formatBigNumber(myPower), tostring(affordable)))
                return affordable
            end
            return false
        end)
        return success and result
    end

    -- Helper: Gets Keeper prompt and Anchor part safely
    local function getKeeperPromptAndAnchor(gate)
        local activeWorld = getActiveWorld()
        local success, result = pcall(function()
            local goalFolder = resolveWorldFolder(activeWorld)
            local gateFolder = goalFolder and resolveGateFolder(goalFolder, gate)
            local keeperStatus = gateFolder and gateFolder:FindFirstChild("KeeperStatus")
            local anchor = keeperStatus and keeperStatus:FindFirstChild("Anchor")
            local prompt = anchor and (anchor:FindFirstChild("FootballKeeperPrompt") or anchor:FindFirstChildOfClass("ProximityPrompt"))
            return {Prompt = prompt, Anchor = anchor}
        end)
        return success and result or nil
    end

    -- Helper: Universally fires a proximity prompt (native hook first, simulation fallback)
    local function firePrompt(prompt)
        if not prompt then return end
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
        else
            local holdTime = prompt.HoldDuration or 0
            simulatePhysicalKeyPress(holdTime, prompt.KeyboardKeyCode or Enum.KeyCode.E)
        end
    end

    -- Helper: Checks whether the Goal fight UI is active
    local function isGoalUIActive()
        local success, active = pcall(function()
            local goalGui = LocalPlayer.PlayerGui:FindFirstChild("Goal")
            return goalGui and goalGui.Enabled
        end)
        return success and active
    end

    -- Helper: Performs a single simulated click in the middle of the Goal UI Click button
    local function clickGoal()
        pcall(function()
            local goalGui = LocalPlayer.PlayerGui:FindFirstChild("Goal")
            if goalGui and goalGui.Enabled then
                local clickBtn = goalGui:FindFirstChild("Click") or (goalGui:FindFirstChild("Frame") and goalGui.Frame:FindFirstChild("Click"))
                if clickBtn then
                    local absPos = clickBtn.AbsolutePosition
                    local absSize = clickBtn.AbsoluteSize
                    local clickX = absPos.X + (absSize.X / 2)
                    local clickY = absPos.Y + (absSize.Y / 2)
                    if VirtualInputManager then
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                        task.wait(0.01)
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                    end
                end
            end
        end)
    end

    -- Helper: Teleports player's character to a Vector3 position
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(pos)
            return true
        end
        return false
    end

    -- Helper: Verifies if the selected gate's keeper status is Unlocked
    local function isGateUnlocked()
        local activeWorld = getActiveWorld()
        -- Boundaries transition checks matching game gate structures
        if selectedGate == "11" then
            return isSpecificGateUnlocked("World1", "10")
        elseif selectedGate == "21" then
            return isSpecificGateUnlocked("World2", "20")
        elseif selectedGate == "31" then
            return isSpecificGateUnlocked("World3", "30")
        end

        return isSpecificGateUnlocked(activeWorld, selectedGate)
    end

    -- Helper: Safely resolve the path to the selected target part
    local function getTargetPart()
        local success, part = pcall(function()
            local activeWorld = getActiveWorld()
            local goalFolder = resolveWorldFolder(activeWorld)
            local gateFolder = resolveGateFolder(goalFolder, selectedGate)
            return gateFolder.Wins.Anchor
        end)
        return success and part or nil
    end

    -- Helper: Simulates physical touch interaction at target location and returns to original position
    local function fireTouch()
        if not isGateUnlocked() then
            local now = tick()
            if now - lastLockWarning > 5 then
                warn("[Auto Win] Selected Gate is locked. Farms will resume once unlocked.")
                lastLockWarning = now
            end
            return
        end

        local targetPart = getTargetPart()
        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")

        if targetPart and rootPart then
            -- 1. Cache the original CFrame before the sequence begins
            local originalCFrame = rootPart.CFrame

            -- 2. Teleport client to the target win trigger to process server collision bounds
            rootPart.CFrame = targetPart.CFrame
            task.wait(0.08) -- Minimum physical latency allowance for engine update

            -- 3. Execute touch bounds verification via client pipeline
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(targetPart, rootPart, 0) -- Touch began
                task.wait(0.02)
                firetouchinterest(targetPart, rootPart, 1) -- Touch ended
            end

            -- 4. Restore character positioning seamlessly to original vector coordinates
            rootPart.CFrame = originalCFrame
        else
            warn("[Error] Target part or your character's HumanoidRootPart was not found.")
        end
    end

    -- Safely resolve the path to the ProximityPrompt and its parent part on each tick
    local function getPromptAndParent()
        local eggWorld, eggName = selectedEggCombo:match("^(World%d+)%s*-%s*(Egg%d+)$")
        if not eggWorld or not eggName then return nil end

        local success, result = pcall(function()
            local eggFolder = workspace.Eggs[eggWorld][eggName]
            local primary = eggFolder.PetSystemEggModel.Primary
            local prompt = primary:FindFirstChildOfClass("ProximityPrompt") or primary:FindFirstChild(eggName)
            return {Prompt = prompt, Part = primary}
        end)
        return success and result or nil
    end

    -- Simulates an actual physical key hold/release using the game engine input pipeline
    local function simulatePhysicalKeyPress(duration, keyCode)
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game) -- Press designated key down
            task.wait(duration + 0.05) -- Hold for the prompt duration + a tiny buffer
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game) -- Release designated key
        else
            warn("[Unsupported] VirtualInputManager is not available on this executor.")
        end
    end

    -- Teleports the egg directly to you, physically holds selected key, and teleports the egg back
    local function executeInteraction()
        -- Affordability Check
        local affordable, cost, currentWins = canAffordEgg()
        if not affordable then
            local now = tick()
            if now - lastAffordWarning > 5 then
                warn(string.format("[Auto Hatch] Cannot afford selected egg. Cost: %s, Current Wins: %s", formatBigNumber(cost), formatBigNumber(currentWins)))
                lastAffordWarning = now
            end
            return
        end

        local target = getPromptAndParent()
        if not target or not target.Prompt or not target.Part then
            return
        end

        local prompt = target.Prompt
        local parentPart = target.Part

        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")

        if rootPart and parentPart then
            -- 1. Store the egg's original position
            local originalCFrame = parentPart.CFrame 
            
            -- 2. Teleport the EGG directly to your position client-side (You do not move)
            parentPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2) -- Places it 2 studs in front of you
            
            -- 3. Let the client engine register the prompt's updated close-range position
            task.wait(0.1)
            
            -- 4. Simulate the hardware keypress on the prompt with chosen key
            local holdTime = prompt.HoldDuration or 0
            simulatePhysicalKeyPress(holdTime, selectedHatchKey)
            
            -- 5. Give the server a moment to accept the transaction, then restore the egg to its spot
            task.wait(0.05)
            parentPart.CFrame = originalCFrame
        end
    end

    -- UI: Automation Utilities Section
    elements:Label("🔥 Automation Utilities", parent)

    -- Pre-declare the dropdown variables to reference them in the callbacks
    local dropdownW1, dropdownW2, dropdownW3, dropdownW4

    local function updateGateDropdownVisibility()
        local activeWorld = getActiveWorld()
        if dropdownW1 then dropdownW1.Visible = (activeWorld == "World1") end
        if dropdownW2 then dropdownW2.Visible = (activeWorld == "World2") end
        if dropdownW3 then dropdownW3.Visible = (activeWorld == "World3") end
        if dropdownW4 then dropdownW4.Visible = (activeWorld == "World4") end
    end

    -- Dropdown to pick the World
    elements:Dropdown("Select World", parent, worlds, selectedWorld, function(value)
        selectedWorld = value
        selectedGate = selectedGates[value] or "4"
        updateGateDropdownVisibility()
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 1
    dropdownW1 = elements:Dropdown("Select Win Anchor (World 1)", parent, gatesW1, "4", function(value)
        selectedGates.World1 = value
        selectedGate = value
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 2
    dropdownW2 = elements:Dropdown("Select Win Anchor (World 2)", parent, gatesW2, "11", function(value)
        selectedGates.World2 = value
        selectedGate = value
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 3
    dropdownW3 = elements:Dropdown("Select Win Anchor (World 3)", parent, gatesW3, "21", function(value)
        selectedGates.World3 = value
        selectedGate = value
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 4
    dropdownW4 = elements:Dropdown("Select Win Anchor (World 4)", parent, gatesW4, "31", function(value)
        selectedGates.World4 = value
        selectedGate = value
    end)

    -- Align initial state visibility
    updateGateDropdownVisibility()

    -- Textbox to change how fast it transmits (in seconds)
    elements:Textbox("Transmit Interval (s)", parent, tostring(loopInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            loopInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number for the interval.")
        end
    end)

    -- Toggle for Auto Rebirth Checking
    elements:Toggle("Auto Rebirth", parent, false, function(state)
        if not uiLoaded or not state then
            autoRebirthActive = false
            return
        end

        autoRebirthActive = true
        task.spawn(function()
            while autoRebirthActive do
                checkAndExecuteRebirth()
                task.wait(2.0)
            end
        end)
    end)

    -- Toggle for Auto Fight Keeper
    elements:Toggle("Auto Fight Keeper", parent, false, function(state)
        if not uiLoaded or not state then
            autoFightActive = false
            return
        end

        autoFightActive = true
        task.spawn(function()
            local fighting = false
            local savedCFrame = nil

            while autoFightActive do
                local inFight = isGoalUIActive()

                if inFight then
                    fighting = true
                    clickGoal()
                    task.wait(0.05) -- clicks at 20 CPS
                else
                    if fighting then
                        -- Finished a fight, restore previous position
                        fighting = false
                        local char = LocalPlayer.Character
                        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                        if rootPart and savedCFrame then
                            rootPart.CFrame = savedCFrame
                        end
                        savedCFrame = nil
                        task.wait(1.0)
                    else
                        -- Dynamically resolve the next locked gate to challenge
                        local targetGate = getCurrentTargetGate()
                        
                        -- Not fighting, check power capabilities for this target gate
                        local canBeat = checkCanBeatKeeper(targetGate)
                        if canBeat then
                            local target = getKeeperPromptAndAnchor(targetGate)
                            if target and target.Prompt and target.Anchor then
                                local char = LocalPlayer.Character
                                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                                if rootPart then
                                    savedCFrame = rootPart.CFrame
                                    
                                    -- Teleport safely 2 studs above the Keeper Anchor
                                    rootPart.CFrame = target.Anchor.CFrame * CFrame.new(0, 2, 0)
                                    task.wait(0.2) -- Upgraded delay to settle physics coordinates

                                    -- Rapid-trigger loop until fight registers successfully
                                    local startAttempt = tick()
                                    while autoFightActive and not isGoalUIActive() and (tick() - startAttempt < 2.0) do
                                        firePrompt(target.Prompt)
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                        task.wait(1.5)
                    end
                end
            end
        end)
    end)

    -- Toggle for Touch Farm Loop
    elements:Toggle("Auto Win Farm", parent, false, function(state)
        if not uiLoaded or not state then
            winFarmActive = false
            return
        end

        winFarmActive = true
        task.spawn(function()
            while winFarmActive do
                fireTouch()
                task.wait(loopInterval)
            end
        end)
    end)

    -- UI: AFK Training Section
    elements:Label("⚡ AFK Training", parent)

    -- Dropdown to choose a training target location
    elements:Dropdown("Select AFK Target", parent, trainingChoices, selectedTrainingSpot, function(value)
        selectedTrainingSpot = value
    end)

    -- Toggle to maintain teleport position on the training target
    elements:Toggle("Auto Train (AFK Loop)", parent, false, function(state)
        if not uiLoaded or not state then
            autoTrainActive = false
            return
        end

        autoTrainActive = true
        task.spawn(function()
            while autoTrainActive do
                local spotInfo = trainingSpots[selectedTrainingSpot]
                if spotInfo then
                    local currentRebirths = getRebirthCount()
                    if currentRebirths >= spotInfo.req then
                        teleportTo(spotInfo.pos)
                    else
                        local now = tick()
                        if now - lastTrainWarning > 5 then
                            warn(string.format("[Auto Train] Blocked. Requires %d Rebirths (You have %d).", spotInfo.req, currentRebirths))
                            lastTrainWarning = now
                        end
                    end
                end
                task.wait(1.5) -- Periodically re-aligns position against game reset scripts
            end
        end)
    end)

    -- UI: Egg Hatching Section
    elements:Label("🥚 Hatching Utilities", parent)

    -- Dropdown to pick the target Egg
    elements:Dropdown("Select Egg Target", parent, eggChoices, selectedEggCombo, function(value)
        selectedEggCombo = value
        hasPressedT = false
    end)

    -- Dynamically read player upgrades to determine true visual hatch limit options
    local dynamicHatchLimit = getUpgradedHatchAmount()
    local modeROption = string.format("R (%dx Open)", dynamicHatchLimit)
    local modeTOption = string.format("T (Auto %dx Open)", dynamicHatchLimit)

    -- Dropdown to select Key / Open Mode
    elements:Dropdown("Hatch Mode (Key)", parent, {"E (1x Open)", modeROption, modeTOption}, "E (1x Open)", function(value)
        if value:sub(1, 1) == "E" then
            selectedHatchKey = Enum.KeyCode.E
        elseif value:sub(1, 1) == "R" then
            selectedHatchKey = Enum.KeyCode.R
        elseif value:sub(1, 1) == "T" then
            selectedHatchKey = Enum.KeyCode.T
        end
        hasPressedT = false
    end)

    -- Textbox to adjust hatching speed (in seconds)
    elements:Textbox("Hatch Interval (s)", parent, tostring(hatchInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            hatchInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number for the hatch interval.")
        end
    end)

    -- Toggle for Auto Hatch Loop
    elements:Toggle("Auto Hatch Eggs", parent, false, function(state)
        if not uiLoaded or not state then
            autoHatchActive = false
            hasPressedT = false
            return
        end

        autoHatchActive = true
        task.spawn(function()
            while autoHatchActive do
                if selectedHatchKey == Enum.KeyCode.T then
                    if not hasPressedT then
                        executeInteraction()
                        hasPressedT = true
                    end
                else
                    executeInteraction()
                end
                task.wait(hatchInterval)
            end
        end)
    end)
end