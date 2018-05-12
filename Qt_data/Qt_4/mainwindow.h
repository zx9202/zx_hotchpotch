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
    static QDockWidget* createDockWidget(QWidget* parent, const QString& title, int type);

private Q_SLOTS:
    void slotAddDockWidget();
    void slotSetDockWidgetType();
    void slotDestroyed(QObject *obj);

private:
    int m_widgetIndex;
    QMap<QString, QDockWidget*> m_widgets;
    int m_dockWidgetType;
};

#endif // MAINWINDOW_H
