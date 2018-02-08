#ifndef MYDIALOG_H
#define MYDIALOG_H

#include<QWidget>
#include<QDialog>

class MyDialog : public QDialog
{
    Q_OBJECT

public:
    MyDialog(QWidget *parent = Q_NULLPTR);

public:
    void createUi();
    void createUi_2();
    void createUi_final();
};

#endif // MYDIALOG_H
