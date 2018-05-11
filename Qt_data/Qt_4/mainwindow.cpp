#include "zx_title_bar_widget.h"
#include "mainwindow.h"
#include <QMenuBar>
#include <QPushButton>
#include <QPlainTextEdit>
#include <QMessageBox>
#include <QDateTime>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    createUi();
}

MainWindow::~MainWindow()
{
    m_list.clear();
}

void MainWindow::createUi()
{
    this->setDockOptions(QMainWindow::AnimatedDocks | QMainWindow::AllowNestedDocks | QMainWindow::AllowTabbedDocks | QMainWindow::GroupedDragging);
    this->setAttribute(Qt::WA_DeleteOnClose, true);

    QMenuBar* menuBar = new QMenuBar(this);
    if (true) {
        QMenu* curMenu = new QMenu(tr("操作一览"), this);
        curMenu->addAction(tr("增加DockWidget"), this, SLOT(slotAddDockWidget()));
        curMenu->addAction(tr("定制TitleBarWidget"), this, SLOT(slotCustomizeTitleBarWidget()));
        menuBar->addMenu(curMenu);
    }
    this->setMenuBar(menuBar);

    QString styleSheet;
    styleSheet += "QMainWindow { background : #B7B7B7 }";
    styleSheet += "QMainWindow::separator:hover { background : #666666 }";
    //styleSheet += "QMenuBar { background-color: #C7C7C7 }";
    //styleSheet += "QStatusBar { background-color: #C9C9C9 }";
    this->setStyleSheet(styleSheet);
}

QDockWidget* MainWindow::createDockWidget(QWidget* parent, const QString& title, bool doSetTitleBarWidget)
{
    QDockWidget* curDockWidget = new QDockWidget(title, parent);
    {
        QWidget* mWidget = new QWidget(curDockWidget);
        QVBoxLayout* vLayout = new QVBoxLayout(mWidget);
        if (true) {
            QPlainTextEdit* pte = new QPlainTextEdit(mWidget);
            vLayout->addWidget(pte);
            //
            QString message = QString("%1, %2").arg(title, QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss"));
            pte->appendPlainText(message);
        }
        mWidget->setLayout(vLayout);
        //
        curDockWidget->setWidget(mWidget);
    }
    if (doSetTitleBarWidget) {
        ZxTitleBarWidget* titleBarWidget = new ZxTitleBarWidget(curDockWidget);
        curDockWidget->setTitleBarWidget(titleBarWidget);
    }
    return curDockWidget;
}

void MainWindow::slotAddDockWidget()
{
    QString title; title.sprintf("第%d个页面", m_list.size() + 1);
    QDockWidget* currDockWidget = createDockWidget(this, title, m_customizeTitleBarWidget);
    this->addDockWidget(Qt::RightDockWidgetArea, currDockWidget);
    m_list.append(currDockWidget);
}

void MainWindow::slotCustomizeTitleBarWidget()
{
    m_customizeTitleBarWidget = m_customizeTitleBarWidget ? false : true;
    QString message = QString("已经设置为: [%1]定制TitleBarWidget").arg(m_customizeTitleBarWidget);
    QMessageBox::information(this, "", message);
}
