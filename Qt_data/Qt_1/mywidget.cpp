#include<QMainWindow>
#include<QDialog>
#include<QDockWidget>
#include<QGridLayout>
#include<QPushButton>
#include "mywidget.h"


MyWidget::MyWidget(QWidget *parent/* = Q_NULLPTR */) :QDockWidget(parent)
{
    createUi_final();
}

void MyWidget::createUi()
{
    QWidget* mainWidget = new QWidget(this);
    QGridLayout* mainLayout = new QGridLayout(mainWidget);
    {
        int row = 3, col = 5;
        for (int r = 0; r < row; ++r)
        {
            for (int c = 0; c < col; ++c)
            {
                QString text;
                text.sprintf("r=%d,c=%d", r, c);
                QPushButton* btn = new QPushButton(text, mainWidget);
                mainLayout->addWidget(btn, r, c);
            }
        }
    }
    mainWidget->setLayout(mainLayout);
    this->setWidget(mainWidget);
}

//为了能以一种固定的格式书写界面,我为自己固定了这么一种书写方式.
void MyWidget::createUi_final()
{
    QWidget* mainWidget = this;
    if (dynamic_cast<QDialog*>(this) == nullptr)
    {
        mainWidget = new QWidget(this);
    }

    QGridLayout* mainLayout = new QGridLayout(mainWidget);
    {
        int row = 3, col = 5;
        for (int r = 0; r < row; ++r)
        {
            for (int c = 0; c < col; ++c)
            {
                QString text;
                text.sprintf("r=%d,c=%d", r, c);
                QPushButton* btn = new QPushButton(text, mainWidget);
                mainLayout->addWidget(btn, r, c);
            }
        }
    }
    mainWidget->setLayout(mainLayout);

    if (dynamic_cast<QMainWindow*>(this) != nullptr)
    {
        //setCentralWidget(mainWidget);
    }
    else if (this != mainWidget)
    {
        this->setWidget(mainWidget);
    }
}
