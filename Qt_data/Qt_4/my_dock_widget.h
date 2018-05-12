#ifndef MY_DOCK_WIDGET_H
#define MY_DOCK_WIDGET_H

#include <QDockWidget>
#include <QStyleOption>
#include <QMenu>

class MyDockWidget :public QDockWidget
{
    Q_OBJECT

public:
    explicit MyDockWidget(const QString &title, QWidget *parent = Q_NULLPTR);
    virtual ~MyDockWidget();

Q_SIGNALS:
    void sigContextMenuEvent(QContextMenuEvent*);  // 我破坏了封装.

protected:
    void contextMenuEvent(QContextMenuEvent *event) override;  // 我破坏了封装.

public:
    void fillDefaultActions(QMenu* menu);  // 我破坏了封装.
};


#if 1 //MyDockWidget,BEG.

inline MyDockWidget::MyDockWidget(const QString& title, QWidget *parent /* = Q_NULLPTR */)
    :QDockWidget(title, parent)
{
    this->setFeatures(QDockWidget::DockWidgetMovable | QDockWidget::DockWidgetFloatable);
}

inline MyDockWidget::~MyDockWidget() {}

inline void MyDockWidget::contextMenuEvent(QContextMenuEvent *event)
{
    emit sigContextMenuEvent(event);
    QDockWidget::contextMenuEvent(event);
}

inline void MyDockWidget::fillDefaultActions(QMenu *menu)
{
    QStyleOptionDockWidget opt;
    if (true) {
        QIcon curIcon = this->style()->standardIcon(QStyle::SP_TitleBarCloseButton, &opt, this);
        menu->addAction(curIcon, QObject::tr("关闭"), this, SLOT(close()));
    }
    if (true) {
        QIcon curIcon = this->style()->standardIcon(QStyle::SP_TitleBarMaxButton, &opt, this);
        menu->addAction(curIcon, QObject::tr("最大化"), this, SLOT(showMaximized()));
    }
    if (true) {
        QIcon curIcon = this->style()->standardIcon(QStyle::SP_TitleBarMinButton, &opt, this);
        menu->addAction(curIcon, QObject::tr("最小化"), this, SLOT(showMinimized()));
    }
    if (true) {
        QIcon curIcon = this->style()->standardIcon(QStyle::SP_TitleBarNormalButton, &opt, this);
        menu->addAction(curIcon, QObject::tr("正常化"), this, SLOT(showNormal()));
    }
    if (true) {
        QIcon curIcon = this->style()->standardIcon(QStyle::SP_TitleBarShadeButton, &opt, this);
        menu->addAction(curIcon, QObject::tr("浮动"), this, [this]() {this->setFloating(!this->isFloating()); });
    }
    if (false) {
        QIcon curIcon = this->style()->standardIcon(QStyle::SP_TitleBarUnshadeButton, &opt, this);
        menu->addAction(curIcon, QObject::tr("隐藏"), this, [this]() {this->widget()->isVisible() ? this->widget()->hide() : this->widget()->show(); });
    }
}

/* 例子:
* MyDockWidget* curDockWidget = new MyDockWidget(title, parent);
* QObject::connect(curDockWidget, &MyDockWidget::sigContextMenuEvent,
*     [curDockWidget](QContextMenuEvent*event) {
*     QMenu *menu = new QMenu(curDockWidget);
*     curDockWidget->fillDefaultActions(menu);
*     menu->exec(curDockWidget->cursor().pos());
* });
*/

#endif//MyDockWidget,END.


#endif//MY_DOCK_WIDGET_H
