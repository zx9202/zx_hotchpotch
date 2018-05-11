#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QDockWidget>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:
    void createUi();
    static QDockWidget* createDockWidget(QWidget* parent, const QString& title, bool doSetTitleBarWidget);

private Q_SLOTS:
    void slotAddDockWidget();
    void slotCustomizeTitleBarWidget();

private:
    QList<QDockWidget*> m_list;
    bool m_customizeTitleBarWidget;
};

#endif // MAINWINDOW_H
