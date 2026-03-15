import processing.video.*;

Capture cam;
int cols = 5; // 5 列
int rows = 3; // 3 行 (构成 3x5 的画面布局)
int cellW, cellH;
color[][][] palettes; // 存储每个格子的三种色阶

void setup() {
  size(1280, 768); // 标准分辨率
  cellW = width / cols;
  cellH = height / rows;
  
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("未检测到摄像头");
    exit();
  } else {
    // 关键优化：只用一个格子的尺寸捕获视频，减少处理量！
    cam = new Capture(this, cellW, cellH, cameras[0]);
    cam.start();
  }
  
  palettes = new color[cols][rows][3];
  generatePalettes(); // 初始化配色
}

void generatePalettes() {
  colorMode(HSB, 360, 100, 100);
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float baseHue = random(360);
      // 暗部 (阴影)：互补色、低明度
      palettes[i][j][0] = color((baseHue + 180) % 360, 90, 30);
      // 中灰 (主体)：主色调、高饱和
      palettes[i][j][1] = color(baseHue, 85, 80);
      // 亮部 (高光)：邻近色、高明度
      palettes[i][j][2] = color((baseHue + 60) % 360, 50, 100);
    }
  }
  colorMode(RGB, 255, 255, 255);
}

void draw() {
  if (cam.available()) {
    cam.read();
  }
  cam.loadPixels();
  loadPixels();

  // 遍历 5x3 网格
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      
      // 遍历每个格子的像素
      for (int y = 0; y < cellH; y++) {
        for (int x = 0; x < cellW; x++) {
          
          // 摄像头坐标 (带镜像翻转)
          int camX = cellW - x - 1; 
          color c = cam.pixels[camX + y * cellW];
          
          // 提取灰度 (亮度)
          float b = brightness(c);
          
          // 色阶分离 (Thresholding) -> 波普艺术的核心原理
          color outColor;
          if (b < 85) {
            outColor = palettes[i][j][0];
          } else if (b < 170) {
            outColor = palettes[i][j][1];
          } else {
            outColor = palettes[i][j][2];
          }
          
          // 计算主屏幕的绝对坐标并赋值
          int screenX = i * cellW + x;
          int screenY = j * cellH + y;
          pixels[screenX + screenY * width] = outColor;
        }
      }
    }
  }
  updatePixels(); // 统一更新到屏幕，性能极佳
}

void mousePressed() {
  // 每次点击鼠标，随机刷新所有的艺术配色！
  generatePalettes();
}