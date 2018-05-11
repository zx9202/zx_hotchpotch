#ifndef ZX_TITLE_BAR_WIDGET_H
#define ZX_TITLE_BAR_WIDGET_H

#include <QWidget>
#include <QLabel>

class ZxTitleBarWidget :public QWidget
{
    Q_OBJECT

public:
    explicit ZxTitleBarWidget(QWidget *parent = Q_NULLPTR);
    virtual ~ZxTitleBarWidget();

protected:
    virtual void paintEvent(QPaintEvent *event) override;

private:
    void createUi();

private Q_SLOTS:
    void slotClose();
    void slotShowMaximized();
    void slotShowMinimized();
    void slotShowNormal();
    void slotSetFloating();
    void slotHide();

private:
    QLabel* m_label;
};

//////////////////////////////////////////////////////////////////////////

#if 1 //QDockWidgetTitleButton,BEG.
#include <QAbstractButton>
#include <QStyleOption>
#include <QPainter>
// copy from [C:\Qt\Qt5.9.4\5.9.4\Src\qtbase\src\widgets\widgets\qdockwidget.cpp]
/******************************************************************************
** QDockWidgetTitleButton
*/

class QDockWidgetTitleButton : public QAbstractButton
{
    Q_OBJECT

public:
    QDockWidgetTitleButton(/*QDockWidget*/QWidget *dockWidget);

    QSize sizeHint() const Q_DECL_OVERRIDE;
    QSize minimumSizeHint() const Q_DECL_OVERRIDE
    {
        return sizeHint();
    }

    void enterEvent(QEvent *event) Q_DECL_OVERRIDE;
    void leaveEvent(QEvent *event) Q_DECL_OVERRIDE;
    void paintEvent(QPaintEvent *event) Q_DECL_OVERRIDE;
};


inline QDockWidgetTitleButton::QDockWidgetTitleButton(/*QDockWidget*/QWidget *dockWidget)
    : QAbstractButton(dockWidget)
{
    setFocusPolicy(Qt::NoFocus);
}

inline QSize QDockWidgetTitleButton::sizeHint() const
{
    ensurePolished();

    int size = 2 * style()->pixelMetric(QStyle::PM_DockWidgetTitleBarButtonMargin, 0, this);
    if (!icon().isNull()) {
        int iconSize = style()->pixelMetric(QStyle::PM_SmallIconSize, 0, this);
        QSize sz = icon().actualSize(QSize(iconSize, iconSize));
        size += qMax(sz.width(), sz.height());
    }

    return QSize(size, size);
}

inline void QDockWidgetTitleButton::enterEvent(QEvent *event)
{
    if (isEnabled()) update();
    QAbstractButton::enterEvent(event);
}

inline void QDockWidgetTitleButton::leaveEvent(QEvent *event)
{
    if (isEnabled()) update();
    QAbstractButton::leaveEvent(event);
}

inline void QDockWidgetTitleButton::paintEvent(QPaintEvent *)
{
    QPainter p(this);

    QStyleOptionToolButton opt;
    opt.init(this);
    opt.state |= QStyle::State_AutoRaise;

    if (style()->styleHint(QStyle::SH_DockWidget_ButtonsHaveFrame, 0, this))
    {
        if (isEnabled() && underMouse() && !isChecked() && !isDown())
            opt.state |= QStyle::State_Raised;
        if (isChecked())
            opt.state |= QStyle::State_On;
        if (isDown())
            opt.state |= QStyle::State_Sunken;
        style()->drawPrimitive(QStyle::PE_PanelButtonTool, &opt, &p, this);
    }

    opt.icon = icon();
    opt.subControls = 0;
    opt.activeSubControls = 0;
    opt.features = QStyleOptionToolButton::None;
    opt.arrowType = Qt::NoArrow;
    int size = style()->pixelMetric(QStyle::PM_SmallIconSize, 0, this);
    opt.iconSize = QSize(size, size);
    style()->drawComplexControl(QStyle::CC_ToolButton, &opt, &p, this);
}
#endif//QDockWidgetTitleButton,END.

//////////////////////////////////////////////////////////////////////////

#if 1 //ZxTitleBarWidget,BEG.
#include <QHBoxLayout>
#include <QDockWidget>

inline ZxTitleBarWidget::ZxTitleBarWidget(QWidget *parent /* = Q_NULLPTR */) :QWidget(parent), m_label(nullptr) { createUi(); }

inline ZxTitleBarWidget::~ZxTitleBarWidget() {}

inline void ZxTitleBarWidget::paintEvent(QPaintEvent *event)
{
    QPainter painter(this);
    QRect rect = this->rect();
    painter.setPen(QPen(QColor(185, 185, 185), 2, Qt::SolidLine));
    painter.setBrush(QBrush(QColor(218, 218, 218), Qt::SolidPattern));
    painter.drawRect(rect.left(), rect.top(), rect.width(), rect.height());

    QDockWidget* nativeParent = qobject_cast<QDockWidget*>(this->parent());
    if (nativeParent) {
        if (m_label)
        {
            m_label->setText(nativeParent->windowTitle());
        }
        else
        {
            painter.setPen(QPen(Qt::black, 1, Qt::SolidLine));
            painter.setBrush(Qt::NoBrush);
            painter.drawText(rect.left() + 5, rect.top(), rect.width(), rect.height(), Qt::AlignVCenter, nativeParent->windowTitle());
        }
    }
    QWidget::paintEvent(event);
}

inline void ZxTitleBarWidget::createUi()
{
    QHBoxLayout* layout = new QHBoxLayout(this);

    layout->setSpacing(0);//控件间隔.
    layout->setMargin(0); //控件边距.

    if (true) {
        m_label = new QLabel(this);
        QDockWidget* nativeParent = qobject_cast<QDockWidget*>(this->parent());
        if (nativeParent) { m_label->setText(nativeParent->windowTitle()); }
        layout->addWidget(m_label);
    }

    layout->addStretch();//添加伸缩.

    QStyleOptionDockWidget opt;
    if (true) {
        QDockWidgetTitleButton* btnHide = new QDockWidgetTitleButton(this);
        QObject::connect(btnHide, SIGNAL(clicked()), this, SLOT(slotHide()));
        btnHide->setIcon(this->style()->standardIcon(QStyle::SP_TitleBarUnshadeButton, &opt, this));
        layout->addWidget(btnHide);
    }
    if (true) {
        QDockWidgetTitleButton* btnFloat = new QDockWidgetTitleButton(this);
        QObject::connect(btnFloat, SIGNAL(clicked()), this, SLOT(slotSetFloating()));
        btnFloat->setIcon(this->style()->standardIcon(QStyle::SP_TitleBarShadeButton, &opt, this));
        layout->addWidget(btnFloat);
    }
    if (true) {
        QDockWidgetTitleButton* btnNormal = new QDockWidgetTitleButton(this);
        QObject::connect(btnNormal, SIGNAL(clicked()), this, SLOT(slotShowNormal()));
        btnNormal->setIcon(this->style()->standardIcon(QStyle::SP_TitleBarNormalButton, &opt, this));
        layout->addWidget(btnNormal);
    }
    if (true) {
        QDockWidgetTitleButton* btnMin = new QDockWidgetTitleButton(this);
        QObject::connect(btnMin, SIGNAL(clicked()), this, SLOT(slotShowMinimized()));
        btnMin->setIcon(this->style()->standardIcon(QStyle::SP_TitleBarMinButton, &opt, this));
        layout->addWidget(btnMin);
    }
    if (true) {
        QDockWidgetTitleButton* btnMax = new QDockWidgetTitleButton(this);
        QObject::connect(btnMax, SIGNAL(clicked()), this, SLOT(slotShowMaximized()));
        btnMax->setIcon(this->style()->standardIcon(QStyle::SP_TitleBarMaxButton, &opt, this));
        layout->addWidget(btnMax);
    }
    if (true) {
        QDockWidgetTitleButton* btnClose = new QDockWidgetTitleButton(this);
        btnClose->setSizePolicy(QSizePolicy::Policy::Minimum, QSizePolicy::Policy::Minimum);
        QObject::connect(btnClose, SIGNAL(clicked()), this, SLOT(slotClose()));
        btnClose->setIcon(this->style()->standardIcon(QStyle::SP_TitleBarCloseButton, &opt, this));
        layout->addWidget(btnClose);
    }
    this->setLayout(layout);

    if (false) { //本来想用 setStyleSheet 代替 paintEvent 的, 结果发现不行.
        QString styleSheet;
        styleSheet += "QWidget { background : #DADADA }";
        this->setStyleSheet(styleSheet);
    }
}

inline void ZxTitleBarWidget::slotClose()
{
    QWidget* nativeParent = qobject_cast<QWidget*>(this->parent());
    if (nativeParent) { nativeParent->close(); }
}

inline void ZxTitleBarWidget::slotShowMaximized()
{
    QWidget* nativeParent = qobject_cast<QWidget*>(this->parent());
    if (nativeParent) { nativeParent->showMaximized(); }
}

inline void ZxTitleBarWidget::slotShowMinimized()
{
    QWidget* nativeParent = qobject_cast<QWidget*>(this->parent());
    if (nativeParent) { nativeParent->showMinimized(); }
}

inline void ZxTitleBarWidget::slotShowNormal()
{
    QWidget* nativeParent = qobject_cast<QWidget*>(this->parent());
    if (nativeParent) { nativeParent->showNormal(); }
}

inline void ZxTitleBarWidget::slotSetFloating()
{
    QDockWidget* nativeParent = qobject_cast<QDockWidget*>(this->parent());
    if (nativeParent) { nativeParent->setFloating(!nativeParent->isFloating()); }
}

inline void ZxTitleBarWidget::slotHide()
{
    QDockWidget* nativeParent = qobject_cast<QDockWidget*>(this->parent());
    QWidget* widgetOfDockWidget = nativeParent ? nativeParent->widget() : nullptr;
    if (widgetOfDockWidget) { widgetOfDockWidget->isVisible() ? widgetOfDockWidget->hide() : widgetOfDockWidget->show(); }
}
#endif//ZxTitleBarWidget,END.

#endif//ZX_TITLE_BAR_WIDGET_H
