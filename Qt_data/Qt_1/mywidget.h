#ifndef MYWIDGET_H
#define MYWIDGET_H

#include<QDockWidget>

class MyWidget : public QDockWidget
{
    Q_OBJECT

public:
    MyWidget(QWidget *parent = Q_NULLPTR);

public:
    void createUi();
    void createUi_final();
};

#endif // MYWIDGET_H
