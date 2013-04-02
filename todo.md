setup_ubuntu.sh
===============
* sudo update-alternatives --config editor
* sudo visudo  # 设置不输入密码
* 将最大最小话按钮调整到右边
  Alt-F2 运行 dconf-editor 搜索layout ,将button-layout的值修改为menu:minimize,maximize,close
* 有些命令需要ROOT权限，而有些不需要，怎么处理

