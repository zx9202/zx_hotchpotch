#include<QMainWindow>
#include<QDialog>
#include<QDockWidget>
#include<QGridLayout>
#include<QPushButton>
#include "mydialog.h"

MyDialog::MyDialog(QWidget *parent/* = Q_NULLPTR */) :QDialog(parent)
{
    createUi_final();
}

void MyDialog::createUi()
{
    QGridLayout* mainLayout = new QGridLayout(this);

    int row = 3, col = 5;
    for (int r = 0; r < row; ++r)
    {
        for (int c = 0; c < col; ++c)
        {
            QString text;
            text.sprintf("r=%d,c=%d", r, c);
            QPushButton* btn = new QPushButton(text, this);
            mainLayout->addWidget(btn, r, c);
        }
    }

    this->setLayout(mainLayout);
}

void MyDialog::createUi_2()
{
    QWidget* mainWidget = this;
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
}

//为了能以一种固定的格式书写界面,我为自己固定了这么一种书写方式.
void MyDialog::createUi_final()
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
        //this->setWidget(mainWidget);
    }
}
