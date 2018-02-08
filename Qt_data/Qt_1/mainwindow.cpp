//    F2: 跳转到函数定义
//Ctrl+/: 注释行,取消注释行
//Ctrl+I: 格式化代码
#include<QMainWindow>
#include<QDialog>
#include<QDockWidget>
#include<QMessageBox>
#include<QPushButton>
#include<QGridLayout>
#include "mainwindow.h"
#include "mydialog.h"
#include "mywidget.h"
#include "mymainwindow.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    createUi();
}

MainWindow::~MainWindow()
{

}

void MainWindow::createUi()
{
    QWidget* mainWidget = new QWidget(this);
    {
        QVBoxLayout* mainLayout = new QVBoxLayout(mainWidget);
        mainLayout->setSpacing(0);
        mainLayout->setMargin(0);

        QPushButton* btn4dialog = new QPushButton(tr("btn4dialog"), mainWidget);
        connect(btn4dialog, SIGNAL(clicked(bool)), this, SLOT(slotClicked4dialog(bool)));
        mainLayout->addWidget(btn4dialog);

        QPushButton* btn4widget = new QPushButton(tr("btn4widget"), mainWidget);
        connect(btn4widget, SIGNAL(clicked()), this, SLOT(slotClicked4widget()));
        mainLayout->addWidget(btn4widget);

        QPushButton* btn4mainWindow = new QPushButton(tr("btn4mainWindow"), mainWidget);
        connect(btn4mainWindow, SIGNAL(clicked()), this, SLOT(slotClicked4mainWindow()));
        mainLayout->addWidget(btn4mainWindow);

        mainLayout->addStretch();//添加伸缩

        mainWidget->setLayout(mainLayout);
    }
    setCentralWidget(mainWidget);
}

void MainWindow::slotClicked4dialog(bool b)
{
    MyDialog* p = new MyDialog(this);
    if (false == b || true)
    {
        p->exec();
    }
    else
    {
        p->setVisible(true);
        p->raise();
    }
}

void MainWindow::slotClicked4widget()
{
    MyWidget* p = new MyWidget(this);

    if (false)
    {
        //p->exec();
    }
    else if (false)
    {
        p->setVisible(true);
        p->raise();
    }
    else
    {
        QString title; title.sprintf("%d", m_dockWidgets.size());
        p->setWindowTitle(title);
        p->setFeatures(QDockWidget::DockWidgetMovable);
        if (m_dockWidgets.empty())
        {
            this->addDockWidget(Qt::RightDockWidgetArea, p);
        }
        else
        {
            this->tabifyDockWidget(m_dockWidgets.last(), p);
        }
        m_dockWidgets.push_back(p);
    }
}

void MainWindow::slotClicked4mainWindow()
{
    MyMainWindow* p = new MyMainWindow(this);
    if (false)
    {
        //p->exec();
    }
    else
    {
        p->setVisible(true);
        p->raise();
    }
}
